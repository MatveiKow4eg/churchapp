const { z } = require('zod');

const shopItemTypeEnum = z.enum(['COSMETIC', 'UPGRADE', 'BADGE', 'OTHER']);

const activeOnlySchema = z.preprocess((v) => {
  if (typeof v === 'boolean') return v;

  if (typeof v === 'string') {
    const s = v.trim().toLowerCase();
    if (['false', '0', 'no', 'off'].includes(s)) return false;
    if (['true', '1', 'yes', 'on'].includes(s)) return true;
  }

  return v;
}, z.boolean()).optional().default(true);

const shopItemsQuerySchema = z.object({
  activeOnly: activeOnlySchema,
  type: shopItemTypeEnum.optional(),
  limit: z.coerce.number().int().min(1).max(50).optional().default(30),
  offset: z.coerce.number().int().min(0).optional().default(0)
});

module.exports = {
  shopItemTypeEnum,
  shopItemsQuerySchema
};
