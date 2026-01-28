const express = require('express');
const { z } = require('zod');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireDeveloper } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');

const { prisma } = require('../db/prisma');

const router = express.Router();

// POST /reports
// Auth: any logged-in user
router.post(
  '/',
  requireAuth,
  validate({
    body: z.object({
      text: z.string().trim().min(3).max(2000)
    })
  }),
  async (req, res, next) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Unauthorized' } });
      }

      const report = await prisma.report.create({
        data: {
          userId,
          text: req.body.text.trim(),
          // optional metadata that helps debugging, without leaking anything sensitive
          meta: {
            app: 'mobile'
          }
        },
        select: {
          id: true,
          createdAt: true
        }
      });

      return res.status(201).json({ report });
    } catch (err) {
      return next(err);
    }
  }
);

// GET /reports
// Auth: DEVELOPER only
router.get('/', requireAuth, requireDeveloper, async (req, res, next) => {
  try {
    const items = await prisma.report.findMany({
      orderBy: [{ createdAt: 'desc' }],
      take: 200,
      select: {
        id: true,
        text: true,
        createdAt: true,
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true
          }
        }
      }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

module.exports = { reportRouter: router };
