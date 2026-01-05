const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function getUserInventory(userId) {
  return prisma.inventory.findMany({
    where: { userId },
    orderBy: { acquiredAt: 'desc' },
    select: {
      id: true,
      itemKey: true,
      quantity: true,
      acquiredAt: true
    }
  });
}

async function addItemToInventory(userId, itemKey) {
  const existing = await prisma.inventory.findUnique({
    where: { userId_itemKey: { userId, itemKey } },
    select: { id: true }
  });

  if (existing) {
    throw new HttpError(409, 'ITEM_ALREADY_IN_INVENTORY', 'Item already in inventory');
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true }
  });

  if (!user) {
    throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  }

  return prisma.inventory.create({
    data: {
      userId,
      itemKey
    },
    select: {
      id: true,
      userId: true,
      itemKey: true,
      acquiredAt: true,
      quantity: true
    }
  });
}

async function hasItem(userId, itemKey) {
  const inv = await prisma.inventory.findUnique({
    where: { userId_itemKey: { userId, itemKey } },
    select: { id: true }
  });

  return Boolean(inv);
}

module.exports = {
  prisma,
  HttpError,
  getUserInventory,
  addItemToInventory,
  hasItem
};
