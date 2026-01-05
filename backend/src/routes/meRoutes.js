const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { getInventory } = require('../controllers/meController');

const meRouter = express.Router();

// GET /me/inventory
meRouter.get('/inventory', requireAuth, getInventory);

module.exports = { meRouter };
