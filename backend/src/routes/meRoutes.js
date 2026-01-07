const express = require('express');

const { z } = require('zod');
const { validate } = require('../middleware/validate');
const { requireAuth } = require('../middleware/authMiddleware');
const { getInventory, updateAvatar } = require('../controllers/meController');

const meRouter = express.Router();

// GET /me/inventory
meRouter.get('/inventory', requireAuth, getInventory);

// PUT /me/avatar
meRouter.put(
  '/avatar',
  requireAuth,
  validate({
    body: z.object({
      avatarConfig: z.record(z.any())
    })
  }),
  updateAvatar
);

module.exports = { meRouter };
