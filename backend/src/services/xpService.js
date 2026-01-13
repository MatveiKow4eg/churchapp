'use strict';

const { prisma } = require('../db/prisma');

const {
  getBaseXpByDifficulty,
  applySoftCap,
  getNextLevelXp,
  shouldIncrementStreak,
  getStreakBonusIfAny
} = require('../core/xp/xp_rules');

function startOfLocalDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function endOfLocalDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
}

function getXpFieldByCategory(category) {
  switch (category) {
    case 'SPIRITUAL':
      return 'xpSpiritual';
    case 'SERVICE':
      return 'xpService';
    case 'COMMUNITY':
      return 'xpCommunity';
    case 'CREATIVITY':
      return 'xpCreativity';
    case 'REFLECTION':
      return 'xpReflection';
    case 'OTHER':
      return 'xpOther';
    default:
      throw new Error(`Unknown XP category: ${category}`);
  }
}

function getLifetimeXpFieldByCategory(category) {
  switch (category) {
    case 'SPIRITUAL':
      return 'lifetimeXpSpiritual';
    case 'SERVICE':
      return 'lifetimeXpService';
    case 'COMMUNITY':
      return 'lifetimeXpCommunity';
    case 'CREATIVITY':
      return 'lifetimeXpCreativity';
    case 'REFLECTION':
      return 'lifetimeXpReflection';
    case 'OTHER':
      return 'lifetimeXpOther';
    default:
      throw new Error(`Unknown XP category: ${category}`);
  }
}

function mapTaskCategoryToXpCategory(taskCategory) {
  // TaskCategory enum is a superset used by Tasks; XP uses XpCategory.
  // If a new TaskCategory appears and we don't know it yet, default to OTHER.
  switch (taskCategory) {
    case 'SPIRITUAL':
      return 'SPIRITUAL';
    case 'SERVICE':
      return 'SERVICE';
    case 'COMMUNITY':
      return 'COMMUNITY';
    case 'CREATIVITY':
      return 'CREATIVITY';
    case 'REFLECTION':
      return 'REFLECTION';
    case 'OTHER':
    default:
      return 'OTHER';
  }
}

/**
 * Awards XP for a task completion.
 * Pure DB operation: calculates daily soft-cap + streak bonus and writes XpLedger + updates User in a single transaction.
 */
async function awardTaskXp({ userId, taskId, at = new Date(), tx } = {}) {
  if (!userId) throw new Error('userId is required');
  if (!taskId) throw new Error('taskId is required');

  const atDate = at instanceof Date ? at : new Date(at);
  if (Number.isNaN(atDate.getTime())) throw new Error('Invalid at date');

  const run = async (trx) => {
    // A) Load user + task
    const user = await trx.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('User not found');

    const task = await trx.task.findUnique({ where: { id: taskId } });
    if (!task) throw new Error('Task not found');

    // B) Base XP
    // Difficulty is fixed: admins/users cannot tune XP difficulty per task.
    const difficulty = 'M';
    const baseXp = getBaseXpByDifficulty(difficulty);

    // XP category is derived from task.category.
    const category = mapTaskCategoryToXpCategory(task.category);

    // C) dailyXpSoFar (today)
    const start = startOfLocalDay(atDate);
    const end = endOfLocalDay(atDate);

    const agg = await trx.xpLedger.aggregate({
      where: { userId, createdAt: { gte: start, lt: end } },
      _sum: { xpGranted: true }
    });
    const dailyXpSoFar = agg._sum.xpGranted ?? 0;

    // D) apply soft-cap to task XP
    const { awardedXp } = applySoftCap(dailyXpSoFar, baseXp);

    // E) update streak
    const streakAction = shouldIncrementStreak(user.lastTaskCompletedAt, atDate);

    let newStreakDays;
    if (streakAction === 'SAME_DAY') {
      newStreakDays = user.streakDays;
    } else if (streakAction === 'NEXT_DAY') {
      newStreakDays = user.streakDays + 1;
    } else {
      // RESET (or null lastTaskCompletedAt)
      newStreakDays = 1;
    }

    // Bonus rule: only when moving from yesterday to today.
    const streakBonus = streakAction === 'NEXT_DAY' ? getStreakBonusIfAny(newStreakDays) : 0;

    // F) ledger for TASK (even if 0, for audit/anti-farm visibility)
    await trx.xpLedger.create({
      data: {
        userId,
        taskId,
        xpGranted: awardedXp,
        xpBase: baseXp,
        category,
        source: 'TASK',
        createdAt: atDate
      }
    });

    // G) ledger for STREAK (if any)
    let streakAwarded = 0;
    if (streakBonus > 0) {
      const dailyXpSoFar2 = dailyXpSoFar + awardedXp;
      const applied = applySoftCap(dailyXpSoFar2, streakBonus);
      streakAwarded = applied.awardedXp;

      await trx.xpLedger.create({
        data: {
          userId,
          taskId: null,
          xpGranted: streakAwarded,
          xpBase: streakBonus,
          category: 'OTHER',
          source: 'STREAK',
          createdAt: atDate
        }
      });
    }

    // H) update User XP fields
    const xpField = getXpFieldByCategory(category);
    const lifetimeField = getLifetimeXpFieldByCategory(category);

    const incTotal = awardedXp + streakAwarded;

    // We compute the would-be new levelXp here so we can decide about level-up.
    const nextLevelXpValue = user.levelXp + incTotal;

    // Base update (no level-up yet)
    const updateData = {
      levelXp: { increment: incTotal },
      lifetimeXp: { increment: incTotal },
      [xpField]: { increment: awardedXp },
      [lifetimeField]: { increment: awardedXp },
      streakDays: newStreakDays,
      lastTaskCompletedAt: atDate
    };

    // I) Level-up (only +1 max)
    const need = getNextLevelXp(user.level);

    let leveledUp = false;
    let newLevel = user.level;
    let newLevelXp = nextLevelXpValue;

    if (nextLevelXpValue >= need) {
      leveledUp = true;
      newLevel = user.level + 1;
      newLevelXp = 0;

      // Override increment with reset.
      updateData.level = newLevel;
      updateData.levelXp = 0;

      // Reset current per-category XP bars on level-up.
      updateData.xpSpiritual = 0;
      updateData.xpService = 0;
      updateData.xpCommunity = 0;
      updateData.xpCreativity = 0;
      updateData.xpReflection = 0;
      updateData.xpOther = 0;
    }

    await trx.user.update({
      where: { id: userId },
      data: updateData
    });

    const nextNeedXp = getNextLevelXp(newLevel);

    return {
      awardedXp,
      streakAwarded,
      leveledUp,
      newLevel,
      newLevelXp,
      nextNeedXp
    };
  };

  if (tx) {
    return run(tx);
  }

  return prisma.$transaction(async (trx) => run(trx));
}

module.exports = { awardTaskXp };
