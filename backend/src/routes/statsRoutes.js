const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { statsMeQuerySchema } = require('../validators/statsSchemas');
const { getMyMonthlyStats, getChurchStats } = require('../controllers/statsController');

const statsRouter = express.Router();

// GET /stats/me?month=YYYY-MM
statsRouter.get('/me', requireAuth, validate({ query: statsMeQuerySchema }), getMyMonthlyStats);

// GET /stats/church?month=YYYY-MM (ADMIN/SUPERADMIN)
statsRouter.get(
  '/church',
  requireAuth,
  requireAdmin,
  validate({ query: statsMeQuerySchema }),
  getChurchStats
);

module.exports = { statsRouter };
