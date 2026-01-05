const { z } = require('zod');

const submissionStatusEnum = z.enum(['PENDING', 'APPROVED', 'REJECTED', 'CANCELED']);

const paginationQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).optional().default(30),
  offset: z.coerce.number().int().min(0).optional().default(0),
  sort: z.enum(['new', 'old']).optional().default('new')
});

const listMySubmissionsQuerySchema = paginationQuerySchema.extend({
  status: submissionStatusEnum.optional()
});

const listPendingSubmissionsQuerySchema = paginationQuerySchema;

module.exports = {
  submissionStatusEnum,
  paginationQuerySchema,
  listMySubmissionsQuerySchema,
  listPendingSubmissionsQuerySchema
};
