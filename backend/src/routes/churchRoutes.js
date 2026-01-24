const express = require('express');

const { validate } = require('../middleware/validate');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { createChurchSchema, searchChurchesQuerySchema, joinChurchBodySchema } = require('../validators/churchSchemas');
const { z } = require('zod');
const churchController = require('../controllers/churchController');

const joinParamsSchema = z.object({
  id: z.string().cuid('Invalid churchId (expected cuid)')
});

const router = express.Router();

// GET /churches?search=<>&limit=<>
// Access: public
router.get(
  '/',
  validate({ query: searchChurchesQuerySchema }),
  churchController.search
);

// POST /churches
// Access: ADMIN or SUPERADMIN
router.post(
  '/',
  requireAuth,
  requireAdmin,
  validate({ body: createChurchSchema }),
  churchController.create
);

// POST /churches/:id/join
router.post(
  '/:id/join',
  requireAuth,
  validate({ params: joinParamsSchema, body: joinChurchBodySchema }),
  churchController.joinChurch
);

// POST /churches/:id/join-code/rotate
// Access: ADMIN or SUPERADMIN
router.post(
  '/:id/join-code/rotate',
  requireAuth,
  requireAdmin,
  validate({ params: joinParamsSchema }),
  churchController.rotateJoinCode
);

module.exports = { churchRouter: router };
