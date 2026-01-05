const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

function parseMonthRange(monthYYYYMM) {
  // monthYYYYMM: "2026-01" (validated by zod in controller)
  const [y, mm] = monthYYYYMM.split('-').map((x) => Number(x));
  const start = new Date(Date.UTC(y, mm - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(y, mm, 1, 0, 0, 0, 0));
  return { start, end };
}

async function getUserMonthlyStats({ userId, churchId, monthYYYYMM }) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  const [
    tasksApprovedCount,
    monthlyEntries,
    currentBalanceAgg,
    topCategoriesAgg
  ] = await prisma.$transaction([
    prisma.submission.count({
      where: {
        userId,
        status: 'APPROVED',
        decidedAt: { gte: start, lt: end }
      }
    }),
    prisma.pointsLedger.findMany({
      where: {
        userId,
        churchId,
        createdAt: { gte: start, lt: end }
      },
      select: { amount: true }
    }),
    prisma.pointsLedger.aggregate({
      where: { userId, churchId },
      _sum: { amount: true }
    }),
    // top 3 categories for approved tasks in the month
    prisma.submission.groupBy({
      by: ['taskId'],
      where: {
        userId,
        status: 'APPROVED',
        decidedAt: { gte: start, lt: end }
      },
      _count: { taskId: true }
    })
  ]);

  let pointsEarned = 0;
  let pointsSpent = 0;

  for (const e of monthlyEntries) {
    if (e.amount > 0) pointsEarned += e.amount;
    else if (e.amount < 0) pointsSpent += Math.abs(e.amount);
  }

  // Convert taskId counts to category counts (top 3)
  // groupBy by taskId first to avoid joining in groupBy (Prisma limitation);
  // then fetch categories for taskIds.
  const taskIdCounts = topCategoriesAgg
    .map((x) => ({ taskId: x.taskId, count: x._count.taskId }))
    .filter((x) => x.taskId);

  let topCategories = [];
  if (taskIdCounts.length > 0) {
    const taskIds = taskIdCounts.map((x) => x.taskId);

    const tasks = await prisma.task.findMany({
      where: { id: { in: taskIds } },
      select: { id: true, category: true }
    });

    const taskCategoryById = new Map(tasks.map((t) => [t.id, t.category]));

    const categoryCounts = new Map();
    for (const t of taskIdCounts) {
      const category = taskCategoryById.get(t.taskId);
      if (!category) continue;
      categoryCounts.set(category, (categoryCounts.get(category) || 0) + t.count);
    }

    topCategories = Array.from(categoryCounts.entries())
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 3);
  }

  const currentBalance = currentBalanceAgg._sum.amount ?? 0;

  return {
    month: monthYYYYMM,
    tasksApprovedCount,
    pointsEarned,
    pointsSpent,
    netPoints: pointsEarned - pointsSpent,
    currentBalance,
    topCategories
  };
}

async function getChurchMonthlyStats({ churchId, monthYYYYMM }) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  const [
    activeUsersCount,
    approvedSubmissionsCount,
    pendingSubmissionsCount,
    monthlyChurchEntries,
    topUsersAgg,
    topTasksAgg
  ] = await prisma.$transaction([
    prisma.user.count({
      where: {
        churchId,
        status: 'ACTIVE'
      }
    }),
    prisma.submission.count({
      where: {
        churchId,
        status: 'APPROVED',
        decidedAt: { gte: start, lt: end }
      }
    }),
    // MVP choice: pending = current queue (no month filter)
    prisma.submission.count({
      where: {
        churchId,
        status: 'PENDING'
      }
    }),
    prisma.pointsLedger.findMany({
      where: {
        churchId,
        createdAt: { gte: start, lt: end }
      },
      select: {
        userId: true,
        amount: true
      }
    }),
    prisma.pointsLedger.groupBy({
      by: ['userId'],
      where: {
        churchId,
        createdAt: { gte: start, lt: end }
      },
      _sum: { amount: true }
    }),
    prisma.submission.groupBy({
      by: ['taskId'],
      where: {
        churchId,
        status: 'APPROVED',
        decidedAt: { gte: start, lt: end }
      },
      _count: { taskId: true },
      orderBy: {
        _count: {
          taskId: 'desc'
        }
      },
      take: 5
    })
  ]);

  let totalPointsEarned = 0;
  let totalPointsSpent = 0;

  for (const e of monthlyChurchEntries) {
    if (e.amount > 0) totalPointsEarned += e.amount;
    else if (e.amount < 0) totalPointsSpent += Math.abs(e.amount);
  }

  // top 10 users by net points (sum ledger amount within month)
  const topUserIds = topUsersAgg
    .slice()
    .sort((a, b) => (b._sum.amount ?? 0) - (a._sum.amount ?? 0))
    .slice(0, 10)
    .map((x) => x.userId);

  let topUsers = [];
  if (topUserIds.length > 0) {
    const users = await prisma.user.findMany({
      where: { id: { in: topUserIds } },
      select: {
        id: true,
        firstName: true,
        lastName: true
      }
    });

    const userById = new Map(users.map((u) => [u.id, u]));

    topUsers = topUsersAgg
      .map((x) => ({ userId: x.userId, netPoints: x._sum.amount ?? 0 }))
      .filter((x) => userById.has(x.userId))
      .sort((a, b) => b.netPoints - a.netPoints)
      .slice(0, 10)
      .map((x) => ({
        user: userById.get(x.userId),
        netPoints: x.netPoints
      }));
  }

  // Optional: topTasks (already aggregated by count)
  let topTasks = [];
  const taskIds = topTasksAgg.map((x) => x.taskId).filter(Boolean);
  if (taskIds.length > 0) {
    const tasks = await prisma.task.findMany({
      where: { id: { in: taskIds } },
      select: { id: true, title: true }
    });

    const taskById = new Map(tasks.map((t) => [t.id, t]));

    topTasks = topTasksAgg
      .map((x) => ({ taskId: x.taskId, approvedCount: x._count.taskId }))
      .filter((x) => taskById.has(x.taskId))
      .map((x) => ({
        task: taskById.get(x.taskId),
        approvedCount: x.approvedCount
      }));
  }

  return {
    month: monthYYYYMM,
    activeUsersCount,
    approvedSubmissionsCount,
    pendingSubmissionsCount,
    totalPointsEarned,
    totalPointsSpent,
    topUsers,
    topTasks
  };
}

async function getChurchLeaderboard({
  churchId,
  monthYYYYMM,
  limit = 20,
  offset = 0,
  includeMeUserId
}) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  // 1) Find active users in church (needed to filter leaderboard)
  const activeUsers = await prisma.user.findMany({
    where: { churchId, status: 'ACTIVE' },
    select: { id: true, firstName: true, lastName: true }
  });

  const activeUserIds = activeUsers.map((u) => u.id);
  const userById = new Map(activeUsers.map((u) => [u.id, u]));

  if (activeUserIds.length === 0) {
    return {
      month: monthYYYYMM,
      items: [],
      limit,
      offset,
      total: 0,
      ...(includeMeUserId ? { me: { rank: null, netPoints: 0 } } : {})
    };
  }

  // 2) Aggregate net points for month for active users
  const sums = await prisma.pointsLedger.groupBy({
    by: ['userId'],
    where: {
      churchId,
      userId: { in: activeUserIds },
      createdAt: { gte: start, lt: end }
    },
    _sum: { amount: true }
  });

  const netByUserId = new Map(sums.map((s) => [s.userId, s._sum.amount ?? 0]));

  // Users with 0 points in month are still part of the ranking
  const allRows = activeUserIds
    .map((userId) => ({ userId, netPoints: netByUserId.get(userId) ?? 0 }))
    .sort((a, b) => b.netPoints - a.netPoints);

  const paged = allRows.slice(offset, offset + limit);

  const items = paged
    .filter((r) => userById.has(r.userId))
    .map((r, idx) => ({
      rank: offset + idx + 1,
      user: userById.get(r.userId),
      netPoints: r.netPoints
    }));

  let me;
  if (includeMeUserId) {
    const meIndex = allRows.findIndex((r) => r.userId === includeMeUserId);
    if (meIndex >= 0) {
      me = {
        rank: meIndex + 1,
        netPoints: allRows[meIndex].netPoints
      };
    } else {
      // current user not ACTIVE / not in this church
      me = { rank: null, netPoints: 0 };
    }
  }

  return {
    month: monthYYYYMM,
    items,
    limit,
    offset,
    total: items.length,
    ...(me ? { me } : {})
  };
}

module.exports = {
  prisma,
  HttpError,
  getUserMonthlyStats,
  getChurchMonthlyStats,
  getChurchLeaderboard
};
