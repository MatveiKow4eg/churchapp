const express = require('express');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { createSubmissionSchema } = require('../validators/submissionSchemas');
const {
  approveSubmissionParamsSchema,
  approveSubmissionBodySchema
} = require('../validators/submissionApproveSchema');
const {
  listMySubmissionsQuerySchema,
  listPendingSubmissionsQuerySchema
} = require('../validators/submissionQuerySchemas');
const {
  createSubmission,
  listMine,
  listPending,
  approve,
  reject
} = require('../controllers/submissionController');

const submissionRouter = express.Router();

// POST /submissions
submissionRouter.post('/', requireAuth, validate({ body: createSubmissionSchema }), createSubmission);

// GET /submissions/mine
submissionRouter.get('/mine', requireAuth, validate({ query: listMySubmissionsQuerySchema }), listMine);

// GET /submissions/pending (ADMIN/SUPERADMIN)
submissionRouter.get(
  '/pending',
  requireAuth,
  requireAdmin,
  validate({ query: listPendingSubmissionsQuerySchema }),
  listPending
);

// POST /submissions/:id/approve (ADMIN/SUPERADMIN)
submissionRouter.post(
  '/:id/approve',
  requireAuth,
  requireAdmin,
  validate({ params: approveSubmissionParamsSchema, body: approveSubmissionBodySchema }),
  approve
);

// POST /submissions/:id/reject (ADMIN/SUPERADMIN)
submissionRouter.post(
  '/:id/reject',
  requireAuth,
  requireAdmin,
  validate({ params: approveSubmissionParamsSchema, body: approveSubmissionBodySchema }),
  reject
);

module.exports = { submissionRouter };
