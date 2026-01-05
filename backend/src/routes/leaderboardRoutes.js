const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validate');
const { leaderboardQuerySchema } = require('../validators/leaderboardSchemas');
const { getLeaderboard } = require('../controllers/leaderboardController');

const leaderboardRouter = express.Router();

// GET /leaderboard?month=YYYY-MM
leaderboardRouter.get('/', requireAuth, validate({ query: leaderboardQuerySchema }), getLeaderboard);

module.exports = { leaderboardRouter };
