const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { createChurchSchema } = require('../validators/churchSchemas');

const { prisma } = require('../db/prisma');
const { createChurch } = require('../services/churchService');

const router = express.Router();

// All /admin endpoints require SUPERADMIN
router.use(requireAuth);

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

// GET /admin/users
// Access: SUPERADMIN
router.get('/users', async (req, res, next) => {
  try {
    const items = await prisma.user.findMany({
      orderBy: [{ createdAt: 'desc' }],
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarUpdatedAt: true,
        avatarConfig: true
      }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// PATCH /admin/users/:id
// Access: SUPERADMIN
router.patch('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, status, churchId, firstName, lastName } = req.body ?? {};

    const data = {};
    if (role !== undefined) data.role = role;
    if (status !== undefined) data.status = status;
    if (churchId !== undefined) data.churchId = churchId;
    if (firstName !== undefined) data.firstName = firstName;
    if (lastName !== undefined) data.lastName = lastName;

    if (Object.keys(data).length === 0) {
      return res.status(400).json({ code: 'BAD_REQUEST', message: 'No fields to update' });
    }

    const user = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarUpdatedAt: true,
        avatarConfig: true
      }
    });

    return res.json({ user });
  } catch (err) {
    return next(err);
  }
});

module.exports = { adminRouter: router };
