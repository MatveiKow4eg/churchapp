const { z } = require('zod');

const shopItemTypeEnum = z.enum(['COSMETIC', 'UPGRADE', 'BADGE', 'OTHER']);

const createItemBodySchema = z.object({
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(500).optional(),
  type: shopItemTypeEnum,
  pricePoints: z.coerce.number().int().min(0).max(1_000_000)
});

const updateItemBodySchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    description: z.string().trim().max(500).optional(),
    type: shopItemTypeEnum.optional(),
    pricePoints: z.coerce.number().int().min(0).max(1_000_000).optional(),
    isActive: z.coerce.boolean().optional()
  })
  .refine((obj) => Object.keys(obj).length > 0, {
    message: 'EMPTY_PATCH'
  });

const itemIdParamsSchema = z.object({
  id: z.string().cuid('Invalid id (expected cuid)')
});

module.exports = {
  shopItemTypeEnum,
  createItemBodySchema,
  updateItemBodySchema,
  itemIdParamsSchema
};
