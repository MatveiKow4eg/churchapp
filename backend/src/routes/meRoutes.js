const express = require('express');

const { z } = require('zod');
const { validate } = require('../middleware/validate');
const { requireAuth } = require('../middleware/authMiddleware');
const {
  getInventory,
  updateAvatar,
  updateProfile,
  leaveChurch,
  changePassword,
  changeEmail
} = require('../controllers/meController');

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

// PUT /me/profile
meRouter.put(
  '/profile',
  requireAuth,
  validate({
    body: z.object({
      firstName: z.string().min(1),
      lastName: z.string().min(1),
      city: z.string().optional().nullable()
    })
  }),
  updateProfile
);

// POST /me/leave-church
meRouter.post('/leave-church', requireAuth, leaveChurch);

// POST /me/change-password
meRouter.post(
  '/change-password',
  requireAuth,
  validate({
    body: z.object({
      currentPassword: z.string().min(1),
      newPassword: z.string().min(6)
    })
  }),
  changePassword
);

// POST /me/change-email
meRouter.post(
  '/change-email',
  requireAuth,
  validate({
    body: z.object({
      newEmail: z.string().trim().email()
    })
  }),
  changeEmail
);

module.exports = { meRouter };
