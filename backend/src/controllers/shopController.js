const shopCatalogService = require('../services/shopCatalogService');
const pointsService = require('../services/pointsService');
const userService = require('../services/userService');
const { prisma } = require('../db/prisma');
const { HttpError } = require('../services/submissionService');

async function listItems(req, res, next) {
  try {
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { activeOnly, limit, offset } = req.query;

    const items = await shopCatalogService.listItems({
      churchId,
      activeOnly,
      limit,
      offset
    });

    return res.status(200).json({
      items,
      limit,
      offset,
      total: items.length
    });
  } catch (err) {
    return next(err);
  }
}

async function purchase(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    // Requirement: user must not be BANNED
    const me = await userService.getUserById(userId);
    if (!me) {
      throw new HttpError(404, 'NOT_FOUND', 'Not found');
    }
    if (me.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const { itemKey } = req.body;

    const result = await prisma.$transaction(async (tx) => {
      const item = await tx.shopCatalogItem.findUnique({
        where: {
          churchId_itemKey: {
            churchId,
            itemKey
          }
        },
        select: {
          itemKey: true,
          pricePoints: true,
          churchId: true,
          isActive: true
        }
      });

      if (!item) {
        throw new HttpError(404, 'NOT_FOUND', 'Not found');
      }

      if (item.churchId !== churchId) {
        throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
      }

      if (!item.isActive) {
        throw new HttpError(409, 'CONFLICT', 'Item inactive');
      }

      const existingInventory = await tx.inventory.findUnique({
        where: {
          userId_itemKey: {
            userId,
            itemKey
          }
        },
        select: { id: true }
      });

      if (existingInventory) {
        throw new HttpError(409, 'CONFLICT', 'Already owned');
      }

      const balanceAgg = await tx.pointsLedger.aggregate({
        where: { userId, churchId },
        _sum: { amount: true }
      });

      const balance = balanceAgg._sum.amount ?? 0;

      if (balance < item.pricePoints) {
        throw new HttpError(409, 'CONFLICT', 'Insufficient points');
      }

      await tx.pointsLedger.create({
        data: {
          churchId,
          userId,
          type: 'PURCHASE',
          amount: -item.pricePoints,
          meta: { itemKey }
        }
      });

      const inventory = await tx.inventory.create({
        data: {
          userId,
          itemKey,
          quantity: 1
        },
        select: {
          id: true,
          itemKey: true,
          acquiredAt: true,
          quantity: true
        }
      });

      return { item, inventory };
    });

    const newBalance = await pointsService.getBalance(userId, churchId);

    return res.status(200).json({
      itemKey: result.item.itemKey,
      pricePoints: result.item.pricePoints,
      balance: newBalance,
      inventory: result.inventory
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listItems,
  purchase
};
