const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { errorHandler } = require('./middleware/errorHandler');
const { validate } = require('./middleware/validate');
const { z } = require('zod');
const { authRouter } = require('./routes/authRoutes');
const { churchRouter } = require('./routes/churchRoutes');
const { taskRouter } = require('./routes/taskRoutes');
const { submissionRouter } = require('./routes/submissionRoutes');
const { shopRouter } = require('./routes/shopRoutes');
const { meRouter } = require('./routes/meRoutes');
const { statsRouter } = require('./routes/statsRoutes');
const { leaderboardRouter } = require('./routes/leaderboardRoutes');
const { adminRouter } = require('./routes/adminRoutes');
const avatarRoutes = require('./routes/avatarRoutes');

const app = express();

// Body parsing
app.use(express.json());

// CORS
// MVP: разрешаем все источники, чтобы было удобно тестировать с эмуляторов/устройств в локальной сети.
// Для продакшена нужно сузить allow-list до конкретных доменов.
app.use(cors({ origin: true, credentials: true }));

// Logs
app.use(morgan('dev'));

// Healthcheck
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    time: new Date().toISOString(),
    version: '0.1.0'
  });
});

// Example endpoint with Zod validation
// GET /echo?text=hello
app.get(
  '/echo',
  validate({
    query: z.object({
      text: z.string().min(1).max(200)
    })
  }),
  (req, res) => {
    res.json({ text: req.query.text });
  }
);

// Mount auth routes
app.use('/auth', authRouter);

// Mount churches routes
app.use('/churches', churchRouter);

// Mount tasks routes
app.use('/tasks', taskRouter);

// Mount submissions routes
app.use('/submissions', submissionRouter);

// Mount shop routes
app.use('/shop', shopRouter);

// Mount me routes
app.use('/me', meRouter);

// Mount stats routes
app.use('/stats', statsRouter);

// Mount leaderboard routes
app.use('/leaderboard', leaderboardRouter);

// Mount admin routes
app.use('/admin', adminRouter);

// Mount avatar proxy routes
app.use(avatarRoutes);
console.log('avatar routes mounted');

// 404 fallback
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found'
    }
  });
});

// Centralized error handler (must be last)
app.use(errorHandler);

module.exports = { app };
