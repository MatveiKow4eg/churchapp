const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { createChurchSchema } = require('../validators/churchSchemas');

const { prisma } = require('../db/prisma');
const { createChurch } = require('../services/churchService');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const router = express.Router();

// All /admin endpoints require SUPERADMIN
router.use(requireAuth);

// Debug helper: if you still see 403, check `error.code` in response.
router.use((req, _res, next) => {
  // eslint-disable-next-line no-console
  console.log('[admin] user:', req.user);
  next();
});

router.use(requireRole('SUPERADMIN'));

// POST /admin/churches
// Access: SUPERADMIN
router.post('/churches', validate({ body: createChurchSchema }), async (req, res, next) => {
  try {
    const church = await createChurch(req.body);
    return res.status(201).json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        createdAt: church.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/churches
// Access: SUPERADMIN
router.get('/churches', async (req, res, next) => {
  try {
    const items = await prisma.church.findMany({
      orderBy: [{ createdAt: 'desc' }],
      select: { id: true, name: true, city: true, createdAt: true }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

module.exports = { adminRouter: router };
