const { z } = require('zod');

const monthYYYYMMSchema = z
  .string()
  .regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'month must be in format YYYY-MM');

const leaderboardQuerySchema = z.object({
  month: monthYYYYMMSchema,
  limit: z.coerce.number().int().min(1).max(50).optional().default(20),
  offset: z.coerce.number().int().min(0).optional().default(0),

  // Correctly parse querystring "true"/"false"
  includeMe: z
    .enum(['true', 'false'])
    .optional()
    .default('true')
    .transform((v) => v === 'true')
});

module.exports = {
  monthYYYYMMSchema,
  leaderboardQuerySchema
};
