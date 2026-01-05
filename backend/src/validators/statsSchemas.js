const { z } = require('zod');

const monthYYYYMMSchema = z
  .string()
  .regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'month must be in format YYYY-MM');

const statsMeQuerySchema = z.object({
  month: monthYYYYMMSchema
});

module.exports = {
  monthYYYYMMSchema,
  statsMeQuerySchema
};
