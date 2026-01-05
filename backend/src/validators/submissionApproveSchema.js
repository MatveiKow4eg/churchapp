const { z } = require('zod');

const approveSubmissionParamsSchema = z.object({
  id: z.string().cuid('Invalid id (expected cuid)')
});

const approveSubmissionBodySchema = z.object({
  commentAdmin: z
    .string()
    .trim()
    .max(300)
    .optional()
});

module.exports = {
  approveSubmissionParamsSchema,
  approveSubmissionBodySchema
};
