const { z } = require('zod');

const monthYYYYMMSchema = z.union([
  z.literal('all'),
  z
    .string()
    .regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'month must be in format YYYY-MM or "all"')
]);

const statsMeQuerySchema = z.object({
  month: monthYYYYMMSchema
});

module.exports = {
  monthYYYYMMSchema,
  statsMeQuerySchema
};
