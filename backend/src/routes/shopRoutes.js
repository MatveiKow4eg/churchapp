const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
// Admin routes removed for catalog-driven shop
const { validate } = require('../middleware/validate');
const { shopItemsQuerySchema } = require('../validators/shopCatalogSchemas');
const { purchaseBodySchema } = require('../validators/shopPurchaseSchemas');
const { listItems, purchase } = require('../controllers/shopController');

const shopRouter = express.Router();

// GET /shop/items
shopRouter.get('/items', requireAuth, validate({ query: shopItemsQuerySchema }), listItems);

// Admin CRUD removed (catalog-driven items). Only seed script updates prices.

// POST /shop/purchase
shopRouter.post('/purchase', requireAuth, validate({ body: purchaseBodySchema }), purchase);

module.exports = { shopRouter };
