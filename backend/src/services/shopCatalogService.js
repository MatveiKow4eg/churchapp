const { prisma } = require('../db/prisma');

async function listItems({ churchId, activeOnly = true, limit = 30, offset = 0 }) {
  return prisma.shopCatalogItem.findMany({
    where: {
      churchId,
      ...(activeOnly ? { isActive: true } : {})
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    skip: offset,
    select: {
      itemKey: true,
      pricePoints: true,
      isActive: true
    }
  });
}

async function getByItemKey({ churchId, itemKey }) {
  return prisma.shopCatalogItem.findUnique({
    where: {
      churchId_itemKey: {
        churchId,
        itemKey
      }
    },
    select: {
      itemKey: true,
      pricePoints: true,
      isActive: true,
      churchId: true
    }
  });
}

module.exports = {
  prisma,
  listItems,
  getByItemKey
};
