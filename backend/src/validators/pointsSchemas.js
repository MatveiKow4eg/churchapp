const { z } = require('zod');

const adminAdjustSchema = z.object({
  userId: z.string().cuid('Invalid userId (expected cuid)'),
  amount: z
    .number()
    .int('amount must be an integer')
    .refine((v) => v !== 0, { message: 'amount must not be 0' }),
  reason: z.string().trim().max(200, 'reason must be at most 200 characters')
});

module.exports = {
  adminAdjustSchema
};
