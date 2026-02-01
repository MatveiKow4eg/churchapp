const { prisma } = require('../db/prisma');
const { monthRangeUtcExclusiveEnd } = require('../utils/time');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

function parseMonthRange(monthYYYYMM) {
  // Accepts 'all' or 'YYYY-MM'
  if (typeof monthYYYYMM === 'string' && monthYYYYMM.toLowerCase() === 'all') {
    return { start: null, end: null };
  }

  const m = /^\d{4}-\d{2}$/.test(monthYYYYMM);
  if (!m) {
    throw new HttpError(400, 'INVALID_MONTH', 'monthYYYYMM must be in format YYYY-MM');
  }

  // Month boundaries are defined in APP_TZ (Europe/Tallinn) and then converted to UTC for DB.
  return monthRangeUtcExclusiveEnd(monthYYYYMM);
}

async function getUserMonthlyStats({ userId, churchId, monthYYYYMM }) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  const [
    tasksApprovedCount,
    tasksRejectedCount,
    monthlyEntries,
    currentBalanceAgg,
    topCategoriesAgg
  ] = await prisma.$transaction([
    prisma.submission.count({
      where: {
        userId,
        status: 'APPROVED',
        // Count should NOT depend on Task existence.
        // We count only submissions that still have taskId OR have a snapshot.
        OR: [{ taskId: { not: null } }, { taskTitle: { not: null } }],
        ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
      }
    }),
    prisma.submission.count({
      where: {
        userId,
        status: 'REJECTED',
        // Same rule as above.
        OR: [{ taskId: { not: null } }, { taskTitle: { not: null } }],
        ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
      }
    }),
    prisma.pointsLedger.findMany({
      where: {
        userId,
        churchId,
        ...(start && end ? { createdAt: { gte: start, lt: end } } : {})
      },
      select: { amount: true }
    }),
    prisma.pointsLedger.aggregate({
      where: { userId, churchId },
      _sum: { amount: true }
    }),
    // top 3 categories for approved tasks in the month
    // IMPORTANT: if the task was deleted later, taskId may be NULL (onDelete: SetNull).
    // Exclude NULL taskId from category aggregation.
    prisma.submission.groupBy({
      by: ['taskId'],
      where: {
        userId,
        status: 'APPROVED',
        taskId: { not: null },
        ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
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
    tasksRejectedCount,
    pointsEarned,
    pointsSpent,
    currentBalance,
    topCategories
  };
}

async function getChurchMonthlyStats({ churchId, monthYYYYMM }) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  const onlineCutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days

  const [
    activeUsersCount,
    onlineUsersCount,
    approvedSubmissionsCount,
    pendingSubmissionsCount,
    monthlyChurchEntries,
    topTasksAgg
  ] = await prisma.$transaction([
    prisma.user.count({
      where: {
        churchId,
        status: 'ACTIVE'
      }
    }),
    prisma.user.count({
      where: {
        churchId,
        status: 'ACTIVE',
        lastSeenAt: { gte: onlineCutoff }
      }
    }),
    prisma.submission.count({
      where: {
        churchId,
        status: 'APPROVED',
        ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
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
        ...(start && end ? { createdAt: { gte: start, lt: end } } : {})
      },
      select: {
        userId: true,
        amount: true
      }
    }),
        prisma.submission.groupBy({
      by: ['taskId'],
      where: {
        churchId,
        status: 'APPROVED',
        ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
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

  // Top users by completed tasks in the month
  // We rank by APPROVED count, then by approval rate.
  const topUsersAgg = await prisma.submission.groupBy({
    by: ['userId', 'status'],
    where: {
      churchId,
      status: { in: ['APPROVED', 'REJECTED'] },
      ...(start && end ? { decidedAt: { gte: start, lt: end } } : {})
    },
    _count: { _all: true }
  });

  const countsByUserId = new Map();
  for (const row of topUsersAgg) {
    const userId = row.userId;
    if (!userId) continue;
    const cur = countsByUserId.get(userId) ?? { approved: 0, rejected: 0 };
    if (row.status === 'APPROVED') cur.approved += row._count._all;
    if (row.status === 'REJECTED') cur.rejected += row._count._all;
    countsByUserId.set(userId, cur);
  }

  const ranked = Array.from(countsByUserId.entries())
    .map(([userId, c]) => {
      const total = c.approved + c.rejected;
      const approvalRate = total > 0 ? c.approved / total : 0;
      return {
        userId,
        tasksApprovedCount: c.approved,
        tasksRejectedCount: c.rejected,
        approvalRate
      };
    })
    .sort((a, b) => {
      if (b.tasksApprovedCount !== a.tasksApprovedCount) {
        return b.tasksApprovedCount - a.tasksApprovedCount;
      }
      if (b.approvalRate !== a.approvalRate) {
        return b.approvalRate - a.approvalRate;
      }
      return b.tasksRejectedCount - a.tasksRejectedCount;
    })
    .slice(0, 5);

  const topUserIds = ranked.map((r) => r.userId);
  let topUsers = [];
  if (topUserIds.length > 0) {
    const users = await prisma.user.findMany({
      where: { id: { in: topUserIds } },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarConfig: true,
        avatarUpdatedAt: true
      }
    });

    const userById = new Map(users.map((u) => [u.id, u]));

    topUsers = ranked
      .filter((r) => userById.has(r.userId))
      .map((r) => ({
        user: userById.get(r.userId),
        tasksApprovedCount: r.tasksApprovedCount,
        tasksRejectedCount: r.tasksRejectedCount,
        approvalRate: r.approvalRate
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

  // Total members (all statuses) — for admin stats footer.
  const totalMembersCount = await prisma.user.count({
    where: { churchId }
  });

  // All church members list (for admin view). Keep it reasonably small by ordering.
  const members = await prisma.user.findMany({
    where: { churchId },
    orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
    select: {
      id: true,
      firstName: true,
      lastName: true,
      status: true,
      avatarConfig: true,
      avatarUpdatedAt: true
    }
  });

  // Derive topCategories from per-task counts
  let topCategories = [];
  if (taskIds.length > 0) {
    const taskCategory = await prisma.task.findMany({
      where: { id: { in: taskIds } },
      select: { id: true, category: true }
    });
    const catByTaskId = new Map(taskCategory.map((t) => [t.id, t.category]));
    const counts = new Map();
    for (const row of topTasksAgg) {
      const cat = catByTaskId.get(row.taskId);
      if (!cat) continue;
      counts.set(cat, (counts.get(cat) || 0) + row._count.taskId);
    }
    topCategories = Array.from(counts.entries())
      .map(([category, approvedCount]) => ({ category, approvedCount }))
      .sort((a, b) => b.approvedCount - a.approvedCount)
      .slice(0, 10);
  }

  return {
    month: monthYYYYMM,
    activeUsersCount,
    onlineUsersCount,
    totalMembersCount,
    approvedSubmissionsCount,
    pendingSubmissionsCount,
    totalPointsEarned,
    totalPointsSpent,
    topUsers,
    topTasks,
    topCategories,
    members
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
      ...(includeMeUserId ? { me: { rank: null, pointsDelta: 0 } } : {})
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
    .map((userId) => ({ userId, pointsDelta: netByUserId.get(userId) ?? 0 }))
    .sort((a, b) => b.pointsDelta - a.pointsDelta);

  const paged = allRows.slice(offset, offset + limit);

  const items = paged
    .filter((r) => userById.has(r.userId))
    .map((r, idx) => ({
      rank: offset + idx + 1,
      user: userById.get(r.userId),
      pointsDelta: r.pointsDelta
    }));

  let me;
  if (includeMeUserId) {
    const meIndex = allRows.findIndex((r) => r.userId === includeMeUserId);
    if (meIndex >= 0) {
      me = {
        rank: meIndex + 1,
        pointsDelta: allRows[meIndex].pointsDelta
      };
    } else {
      // current user not ACTIVE / not in this church
      me = { rank: null, pointsDelta: 0 };
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
