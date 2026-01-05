const { z } = require('zod');

const createSubmissionSchema = z.object({
  taskId: z.string().cuid('Invalid taskId (expected cuid)'),
  commentUser: z.string().trim().max(300, 'commentUser must be at most 300 characters').optional()
});

const rejectSchema = z.object({
  commentAdmin: z.string().trim().max(300, 'commentAdmin must be at most 300 characters').optional()
});

module.exports = {
  createSubmissionSchema,
  rejectSchema
};
