const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function addEntry({ churchId, userId, type, amount, meta }) {
  if (amount === 0) {
    throw new HttpError(400, 'AMOUNT_ZERO', 'amount must not be 0');
  }

  // (опционально) проверим, что user состоит в этой церкви (для консистентности)
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, churchId: true }
  });

  if (!user) {
    throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  }

  if (user.churchId !== churchId) {
    throw new HttpError(409, 'USER_DIFFERENT_CHURCH', 'User belongs to a different church');
  }

  // Пров��рим существование church
  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new HttpError(404, 'CHURCH_NOT_FOUND', 'Church not found');
  }

  return prisma.pointsLedger.create({
    data: {
      churchId,
      userId,
      type,
      amount,
      meta
    }
  });
}

async function getBalance(userId, churchId) {
  const res = await prisma.pointsLedger.aggregate({
    where: { userId, churchId },
    _sum: { amount: true }
  });

  return res._sum.amount ?? 0;
}

function parseMonthRange(monthYYYYMM) {
  // monthYYYYMM: "2026-01"
  const m = /^\d{4}-\d{2}$/.test(monthYYYYMM);
  if (!m) {
    throw new HttpError(400, 'INVALID_MONTH', 'monthYYYYMM must be in format YYYY-MM');
  }

  const [y, mm] = monthYYYYMM.split('-').map((x) => Number(x));
  const start = new Date(Date.UTC(y, mm - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(y, mm, 1, 0, 0, 0, 0));
  return { start, end };
}

/**
 * spent возвращаем как ПОЛОЖИТЕЛЬНОЕ число (абсолют сумм отрицательных),
 * net = earned - spent.
 */
async function getMonthlySummary(userId, churchId, monthYYYYMM) {
  const { start, end } = parseMonthRange(monthYYYYMM);

  const entries = await prisma.pointsLedger.findMany({
    where: {
      userId,
      churchId,
      createdAt: { gte: start, lt: end }
    },
    select: { amount: true }
  });

  let earned = 0;
  let spent = 0;

  for (const e of entries) {
    if (e.amount > 0) earned += e.amount;
    else if (e.amount < 0) spent += Math.abs(e.amount);
  }

  return {
    earned,
    spent,
    net: earned - spent
  };
}

module.exports = {
  prisma,
  HttpError,
  addEntry,
  getBalance,
  getMonthlySummary
};
