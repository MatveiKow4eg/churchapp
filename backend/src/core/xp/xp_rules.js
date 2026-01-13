'use strict';

/**
 * Single source of truth for XP rules.
 * Pure functions only: no Prisma/DB/Express imports.
 */

// --- Constants ---

// Base XP per task difficulty.
const DIFFICULTY_XP = Object.freeze({
  S: 5,
  M: 15,
  L: 35,
  XL: 70,
});

// Streak settings (hidden bonus logic).
const STREAK_DAYS = 7;
const STREAK_BONUS_XP = 60;

// Soft cap tiers for daily XP (hidden anti-grind scaling).
// 0..200 => x1.0, 200..400 => x0.5, 400+ => x0.2
const SOFT_CAP = Object.freeze([
  { upTo: 200, multiplier: 1.0 },
  { upTo: 400, multiplier: 0.5 },
  { upTo: Infinity, multiplier: 0.2 },
]);

// --- Helpers (internal) ---

function assertInteger(name, value) {
  if (!Number.isInteger(value)) {
    throw new Error(`${name} must be an integer`);
  }
}

function startOfLocalDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function daysBetweenLocalDates(a, b) {
  // Compare by local calendar day boundaries to avoid DST/time-of-day issues.
  const a0 = startOfLocalDay(a).getTime();
  const b0 = startOfLocalDay(b).getTime();
  return Math.round((b0 - a0) / (24 * 60 * 60 * 1000));
}

// --- Exported functions ---

/**
 * Returns base XP for a given difficulty (S/M/L/XL).
 * Throws on unknown difficulty to avoid silent rule drift.
 */
function getBaseXpByDifficulty(difficulty) {
  const xp = DIFFICULTY_XP[difficulty];
  if (typeof xp !== 'number') {
    throw new Error(`Unknown difficulty: ${difficulty}`);
  }
  return xp;
}

/**
 * Returns the XP required to level up from the given level.
 * Uses an exponential curve to slow down progression over time.
 */
function getNextLevelXp(level) {
  if (!Number.isFinite(level) || level < 1 || Math.floor(level) !== level) {
    throw new Error(`Invalid level: ${level}`);
  }
  return Math.round(2500 * Math.pow(1.2, level - 1));
}

/**
 * Applies daily soft cap multipliers to XP (anti-grind).
 * Returns awardedXp (floored) + breakdown per tier for audit/debug.
 */
function applySoftCap(dailyXpSoFar, baseXp) {
  assertInteger('dailyXpSoFar', dailyXpSoFar);
  assertInteger('baseXp', baseXp);
  if (dailyXpSoFar < 0) throw new Error('dailyXpSoFar must be >= 0');
  if (baseXp < 0) throw new Error('baseXp must be >= 0');

  let remaining = baseXp;
  let cursor = dailyXpSoFar;

  const multiplierBreakdown = [];
  let totalAwarded = 0;

  for (const tier of SOFT_CAP) {
    if (remaining <= 0) break;

    const tierStart = tier === SOFT_CAP[0] ? 0 : SOFT_CAP[SOFT_CAP.indexOf(tier) - 1].upTo;
    const tierEnd = tier.upTo;

    // If already past this tier, skip it.
    if (cursor >= tierEnd) continue;

    const availableInTier = tierEnd === Infinity ? remaining : Math.max(0, tierEnd - Math.max(cursor, tierStart));
    const take = Math.min(remaining, availableInTier);

    if (take > 0) {
      const awardedForTier = take * tier.multiplier;
      totalAwarded += awardedForTier;

      multiplierBreakdown.push({
        range: [Math.max(cursor, tierStart), Math.max(cursor, tierStart) + take],
        baseXp: take,
        multiplier: tier.multiplier,
        awardedXp: Math.floor(awardedForTier),
      });

      remaining -= take;
      cursor += take;
    }
  }

  return {
    awardedXp: Math.floor(totalAwarded),
    multiplierBreakdown,
  };
}

/**
 * Determines how streak should change given last completion timestamp.
 * Uses server local calendar days (not UTC) to match user perception.
 */
function shouldIncrementStreak(lastTaskCompletedAt, now) {
  const nowDate = now instanceof Date ? now : new Date(now);
  if (Number.isNaN(nowDate.getTime())) throw new Error('Invalid now date');

  if (lastTaskCompletedAt == null) return 'RESET';

  const lastDate = lastTaskCompletedAt instanceof Date
    ? lastTaskCompletedAt
    : new Date(lastTaskCompletedAt);

  if (Number.isNaN(lastDate.getTime())) throw new Error('Invalid lastTaskCompletedAt date');

  const diffDays = daysBetweenLocalDates(lastDate, nowDate);

  if (diffDays === 0) return 'SAME_DAY';
  if (diffDays === 1) return 'NEXT_DAY';
  return 'RESET';
}

/**
 * Returns streak bonus XP for milestone days (every 7 days), else 0.
 * Keeps milestone logic centralized and hidden from user-facing flows.
 */
function getStreakBonusIfAny(newStreakDays) {
  assertInteger('newStreakDays', newStreakDays);
  if (newStreakDays <= 0) return 0;
  return newStreakDays % STREAK_DAYS === 0 ? STREAK_BONUS_XP : 0;
}

module.exports = {
  DIFFICULTY_XP,
  STREAK_DAYS,
  STREAK_BONUS_XP,
  SOFT_CAP,
  getBaseXpByDifficulty,
  getNextLevelXp,
  applySoftCap,
  shouldIncrementStreak,
  getStreakBonusIfAny,
};
