const inventoryService = require('../services/inventoryService');
const { prisma } = require('../db/prisma');
const { HttpError } = require('../services/submissionService');

async function getInventory(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const items = await inventoryService.getUserInventory(userId);

    return res.status(200).json({
      items: items.map((it) => ({
        id: it.id,
        itemKey: it.itemKey,
        acquiredAt: it.acquiredAt,
        quantity: it.quantity
      })),
      total: items.length
    });
  } catch (err) {
    return next(err);
  }
}

async function updateAvatar(req, res, next) {
  try {
    const userId = req.user?.id;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        avatarConfig: req.body.avatarConfig,
        avatarUpdatedAt: new Date()
      },
      select: {
        id: true,
        role: true,
        churchId: true,
        avatarConfig: true,
        avatarUpdatedAt: true
      }
    });

    return res.status(200).json({ user });
  } catch (err) {
    // Prisma throws P2025 when record to update not found
    if (err && err.code === 'P2025') {
      return next(new HttpError(404, 'USER_NOT_FOUND', 'User not found'));
    }
    return next(err);
  }
}

module.exports = {
  getInventory,
  updateAvatar
};
