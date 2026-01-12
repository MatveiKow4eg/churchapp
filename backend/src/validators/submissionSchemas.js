const { z } = require('zod');

const createSubmissionSchema = z.object({
  taskId: z.string().cuid('Invalid taskId (expected cuid)'),
  // For REFLECTION tasks user can write a longer free-form answer.
  commentUser: z.string().trim().max(5000, 'commentUser must be at most 5000 characters').optional()
});

const rejectSchema = z.object({
  commentAdmin: z.string().trim().max(5000, 'commentAdmin must be at most 5000 characters').optional()
});

module.exports = {
  createSubmissionSchema,
  rejectSchema
};
