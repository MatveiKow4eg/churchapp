const inventoryService = require('../services/inventoryService');
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

module.exports = {
  getInventory
};
