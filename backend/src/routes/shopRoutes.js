const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { shopItemsQuerySchema } = require('../validators/shopSchemas');
const { purchaseBodySchema } = require('../validators/shopPurchaseSchemas');
const {
  createItemBodySchema,
  updateItemBodySchema,
  itemIdParamsSchema
} = require('../validators/shopItemSchemas');
const {
  listItems,
  createItem,
  updateItem,
  deactivateItem,
  purchase
} = require('../controllers/shopController');

const shopRouter = express.Router();

// GET /shop/items
shopRouter.get('/items', requireAuth, validate({ query: shopItemsQuerySchema }), listItems);

// POST /shop/items (ADMIN/SUPERADMIN)
shopRouter.post('/items', requireAuth, requireAdmin, validate({ body: createItemBodySchema }), createItem);

// PATCH /shop/items/:id (ADMIN/SUPERADMIN)
shopRouter.patch(
  '/items/:id',
  requireAuth,
  requireAdmin,
  validate({ params: itemIdParamsSchema, body: updateItemBodySchema }),
  updateItem
);

// PATCH /shop/items/:id/deactivate (ADMIN/SUPERADMIN)
shopRouter.patch(
  '/items/:id/deactivate',
  requireAuth,
  requireAdmin,
  validate({ params: itemIdParamsSchema }),
  deactivateItem
);

// POST /shop/purchase
shopRouter.post('/purchase', requireAuth, validate({ body: purchaseBodySchema }), purchase);

module.exports = { shopRouter };
