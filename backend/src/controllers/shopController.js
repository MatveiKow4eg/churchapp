const shopItemService = require('../services/shopItemService');
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

    const { activeOnly, type, limit, offset } = req.query;

    const items = await shopItemService.listItems({
      churchId,
      activeOnly,
      type,
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

async function createItem(req, res, next) {
  try {
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { name, description, type, pricePoints } = req.body;

    const item = await shopItemService.createItem({
      churchId,
      name,
      description,
      type,
      pricePoints
    });

    return res.status(201).json({
      item: {
        id: item.id,
        name: item.name,
        description: item.description,
        type: item.type,
        pricePoints: item.pricePoints,
        isActive: item.isActive,
        createdAt: item.createdAt
      }
    });
  } catch (err) {
    // Unique (churchId, name) -> Prisma P2002 is mapped by errorHandler to 409 CONFLICT
    return next(err);
  }
}

async function updateItem(req, res, next) {
  try {
    const itemId = req.params.id;

    const adminRole = req.user?.role;
    const adminChurchId = req.user?.churchId;

    if (!adminChurchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const existing = await shopItemService.getItemById(itemId);
    if (!existing) {
      throw new HttpError(404, 'NOT_FOUND', 'Not found');
    }

    if (adminRole !== 'SUPERADMIN' && existing.churchId !== adminChurchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const patch = req.body;

    const item = await shopItemService.updateItem(itemId, patch);

    return res.status(200).json({
      item: {
        id: item.id,
        name: item.name,
        description: item.description,
        type: item.type,
        pricePoints: item.pricePoints,
        isActive: item.isActive,
        createdAt: item.createdAt
      }
    });
  } catch (err) {
    if (err && err.message === 'EMPTY_PATCH') {
      return next(new HttpError(400, 'EMPTY_PATCH', 'EMPTY_PATCH'));
    }
    return next(err);
  }
}

async function deactivateItem(req, res, next) {
  try {
    const itemId = req.params.id;

    const adminRole = req.user?.role;
    const adminChurchId = req.user?.churchId;

    if (!adminChurchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const existing = await shopItemService.getItemById(itemId);
    if (!existing) {
      throw new HttpError(404, 'NOT_FOUND', 'Not found');
    }

    if (adminRole !== 'SUPERADMIN' && existing.churchId !== adminChurchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const item = await shopItemService.deactivateItem(itemId);

    return res.status(200).json({
      item: {
        id: item.id,
        name: item.name,
        description: item.description,
        type: item.type,
        pricePoints: item.pricePoints,
        isActive: item.isActive,
        createdAt: item.createdAt
      }
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

    const { itemId } = req.body;

    const result = await prisma.$transaction(async (tx) => {
      const item = await tx.shopItem.findUnique({
        where: { id: itemId },
        select: {
          id: true,
          name: true,
          type: true,
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
          userId_itemId: {
            userId,
            itemId
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
          meta: { itemId }
        }
      });

      const inventory = await tx.inventory.create({
        data: {
          userId,
          itemId,
          quantity: 1
        },
        select: {
          id: true,
          userId: true,
          itemId: true,
          acquiredAt: true
        }
      });

      return { item, inventory };
    });

    const newBalance = await pointsService.getBalance(userId, churchId);

    return res.status(200).json({
      item: {
        id: result.item.id,
        name: result.item.name,
        pricePoints: result.item.pricePoints,
        type: result.item.type
      },
      balance: newBalance,
      inventory: result.inventory
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listItems,
  createItem,
  updateItem,
  deactivateItem,
  purchase
};
