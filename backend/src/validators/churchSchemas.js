const { z } = require('zod');

const nameSchema = z
  .string()
  .trim()
  .min(2, 'name must be at least 2 characters')
  .max(80, 'name must be at most 80 characters');

const citySchema = z
  .string()
  .trim()
  .max(80, 'city must be at most 80 characters');

const createChurchSchema = z.object({
  name: nameSchema,
  city: citySchema.optional()
});

const searchChurchesQuerySchema = z.object({
  search: z
    .string()
    .trim()
    .min(2, 'search must be at least 2 characters'),
  limit: z
    .preprocess((v) => (v === undefined ? undefined : Number(v)), z.number().int().min(1).max(50))
    .optional()
});

module.exports = {
  createChurchSchema,
  searchChurchesQuerySchema
};
