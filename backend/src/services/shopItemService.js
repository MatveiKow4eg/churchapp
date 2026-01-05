const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function listItems({
  churchId,
  activeOnly = true,
  type,
  limit = 30,
  offset = 0
}) {
  return prisma.shopItem.findMany({
    where: {
      churchId,
      ...(activeOnly ? { isActive: true } : {}),
      ...(type ? { type } : {})
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    skip: offset,
    select: {
      id: true,
      name: true,
      description: true,
      type: true,
      pricePoints: true,
      isActive: true,
      createdAt: true
    }
  });
}

async function getItemById(itemId) {
  return prisma.shopItem.findUnique({
    where: { id: itemId },
    select: {
      id: true,
      churchId: true,
      name: true,
      description: true,
      type: true,
      pricePoints: true,
      isActive: true,
      createdAt: true
    }
  });
}

async function createItem({ churchId, name, description, type, pricePoints }) {
  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new HttpError(404, 'CHURCH_NOT_FOUND', 'Church not found');
  }

  return prisma.shopItem.create({
    data: {
      churchId,
      name,
      description,
      type,
      pricePoints
    }
  });
}

async function updateItem(itemId, patch) {
  return prisma.shopItem.update({
    where: { id: itemId },
    data: patch,
    select: {
      id: true,
      name: true,
      description: true,
      type: true,
      pricePoints: true,
      isActive: true,
      createdAt: true
    }
  });
}

async function deactivateItem(itemId) {
  return prisma.shopItem.update({
    where: { id: itemId },
    data: { isActive: false },
    select: {
      id: true,
      name: true,
      description: true,
      type: true,
      pricePoints: true,
      isActive: true,
      createdAt: true
    }
  });
}

module.exports = {
  prisma,
  HttpError,
  listItems,
  getItemById,
  createItem,
  updateItem,
  deactivateItem
};
