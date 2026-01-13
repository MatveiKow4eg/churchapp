const express = require('express');

const { z } = require('zod');
const { validate } = require('../middleware/validate');
const { requireAuth } = require('../middleware/authMiddleware');
const { prisma } = require('../db/prisma');
const { getNextLevelXp } = require('../core/xp/xp_rules');
const {
  getInventory,
  updateAvatar,
  updateProfile,
  leaveChurch,
  changePassword,
  changeEmail
} = require('../controllers/meController');

const meRouter = express.Router();

function clamp01(x) {
  if (x < 0) return 0;
  if (x > 1) return 1;
  return x;
}

function getLevelName(level) {
  if (level === 1) return 'Новичок';
  if (level === 2) return 'Ученик';
  if (level === 3) return 'Практик';
  if (level === 4) return 'Участник';
  if (level === 5) return 'Служитель';
  if (level === 6) return 'Надёжный';
  if (level === 7) return 'Вдохновитель';
  if (level === 8) return 'Наставник';
  if (level === 9) return 'Лидер';
  if (level === 10) return 'Опора';
  return 'Опора+';
}

// GET /me/xp
// Manual test:
//   curl -H "Authorization: Bearer <TOKEN>" http://localhost:3000/me/xp
meRouter.get('/xp', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      // Should not happen because requireAuth sets req.user, but keep guard.
      return res.status(401).json({ error: 'UNAUTHORIZED' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        level: true,
        levelXp: true,
        xpSpiritual: true,
        xpService: true,
        xpCommunity: true,
        xpCreativity: true,
        xpReflection: true,
        xpOther: true,
        streakDays: true,
        lastTaskCompletedAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'NOT_FOUND' });
    }

    const nextLevelXp = getNextLevelXp(user.level);
    const progress = clamp01(nextLevelXp > 0 ? user.levelXp / nextLevelXp : 0);

    return res.json({
      level: user.level,
      levelName: getLevelName(user.level),
      levelXp: user.levelXp,
      nextLevelXp,
      progress,
      categories: {
        spiritual: user.xpSpiritual,
        service: user.xpService,
        community: user.xpCommunity,
        creativity: user.xpCreativity,
        reflection: user.xpReflection,
        other: user.xpOther
      },
      streakDays: user.streakDays,
      lastTaskCompletedAt: user.lastTaskCompletedAt ? user.lastTaskCompletedAt.toISOString() : null
    });
  } catch (err) {
    return next(err);
  }
});

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
