const express = require('express');
const { validate } = require('../middleware/validate');
const { registerSchema } = require('../validators/userSchemas');
const { loginSchema } = require('../validators/authSchemas');
const { register, login, me } = require('../controllers/authController');
const { authMiddleware } = require('../middleware/authMiddleware');

const router = express.Router();

// POST /auth/register
router.post(
  '/register',
  validate({ body: registerSchema }),
  register
);

// POST /auth/login
router.post(
  '/login',
  validate({ body: loginSchema }),
  login
);

// GET /auth/me
router.get('/me', authMiddleware, me);

module.exports = { authRouter: router };
