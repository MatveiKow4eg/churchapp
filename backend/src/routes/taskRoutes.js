const express = require('express');
const { z } = require('zod');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const {
  listTasksQuerySchema,
  createTaskBodySchema,
  updateTaskSchema,
  improveTaskTextBodySchema
} = require('../validators/taskSchemas');
const { cuidSchema } = require('../validators/commonSchemas');
const {
  listTasks,
  getTaskById,
  createTask,
  updateTask,
  deactivateTask,
  deleteTask,
  improveTaskTextController,
  startQuizAttemptController,
  submitQuizAttemptController
} = require('../controllers/taskController');

const taskRouter = express.Router();

// POST /tasks/improve-text (admin only)
// Improves title+description via backend-only Hugging Face call
taskRouter.post(
  '/improve-text',
  requireAuth,
  requireAdmin,
  validate({ body: improveTaskTextBodySchema }),
  improveTaskTextController
);

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

// POST /tasks/:id/quiz/attempts (user)
taskRouter.post(
  '/:id/quiz/attempts',
  requireAuth,
  validate({ params: z.object({ id: cuidSchema }) }),
  startQuizAttemptController
);

// POST /tasks/:id/quiz/attempts/:attemptId/submit (user)
taskRouter.post(
  '/:id/quiz/attempts/:attemptId/submit',
  requireAuth,
  validate({ params: z.object({ id: cuidSchema, attemptId: cuidSchema }), body: z.object({ answers: z.array(z.object({ questionId: cuidSchema, selectedOptionIds: z.array(z.string()) })).optional() }) }),
  submitQuizAttemptController
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

// DELETE /tasks/:id (admin only)
taskRouter.delete(
  '/:id',
  requireAuth,
  requireAdmin,
  validate({ params: z.object({ id: cuidSchema }) }),
  deleteTask
);

// GET /tasks/ping (debug)
taskRouter.get('/ping', (req, res) => res.json({ ok: true }));

module.exports = { taskRouter };
