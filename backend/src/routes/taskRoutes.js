const express = require('express');
const { z } = require('zod');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { listTasksQuerySchema, createTaskBodySchema, updateTaskSchema } = require('../validators/taskSchemas');
const { cuidSchema } = require('../validators/commonSchemas');
const { listTasks, getTaskById, createTask, updateTask, deactivateTask } = require('../controllers/taskController');

const taskRouter = express.Router();

// POST /tasks (admin only)
taskRouter.post('/', requireAuth, requireAdmin, validate({ body: createTaskBodySchema }), createTask);

// GET /tasks
taskRouter.get('/', requireAuth, validate({ query: listTasksQuerySchema }), listTasks);

// GET /tasks/:id
taskRouter.get(
  '/:id',
  requireAuth,
  validate({ params: z.object({ id: cuidSchema }) }),
  getTaskById
);

// PATCH /tasks/:id/deactivate (admin only)
taskRouter.patch(
  '/:id/deactivate',
  requireAuth,
  requireAdmin,
  validate({ params: z.object({ id: cuidSchema }) }),
  deactivateTask
);

// PATCH /tasks/:id (admin only)
taskRouter.patch(
  '/:id',
  requireAuth,
  requireAdmin,
  validate({ params: z.object({ id: cuidSchema }), body: updateTaskSchema }),
  updateTask
);

// GET /tasks/ping (debug)
taskRouter.get('/ping', (req, res) => res.json({ ok: true }));

module.exports = { taskRouter };
