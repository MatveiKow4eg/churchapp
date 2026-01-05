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
      itemId: true,
      quantity: true,
      acquiredAt: true,
      item: {
        select: {
          id: true,
          name: true,
          description: true,
          type: true,
          pricePoints: true
        }
      }
    }
  });
}

async function addItemToInventory(userId, itemId) {
  // MVP: запрещаем повторную покупку/добавление -> 409
  const existing = await prisma.inventory.findUnique({
    where: { userId_itemId: { userId, itemId } },
    select: { id: true }
  });

  if (existing) {
    throw new HttpError(409, 'ITEM_ALREADY_IN_INVENTORY', 'Item already in inventory');
  }

  // Проверим существование user и item (чтобы не ловить FK-ошибки)
  const [user, item] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId }, select: { id: true } }),
    prisma.shopItem.findUnique({ where: { id: itemId }, select: { id: true } })
  ]);

  if (!user) {
    throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  }

  if (!item) {
    throw new HttpError(404, 'SHOP_ITEM_NOT_FOUND', 'Shop item not found');
  }

  return prisma.inventory.create({
    data: {
      userId,
      itemId
    },
    include: { item: true }
  });
}

async function hasItem(userId, itemId) {
  const inv = await prisma.inventory.findUnique({
    where: { userId_itemId: { userId, itemId } },
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
