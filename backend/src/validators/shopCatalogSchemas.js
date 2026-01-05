const { z } = require('zod');

const shopItemsQuerySchema = z.object({
  activeOnly: z
    .preprocess((v) => {
      if (v === undefined) return undefined;
      if (typeof v === 'string') {
        if (v === 'true') return true;
        if (v === 'false') return false;
      }
      return v;
    }, z.boolean())
    .optional()
    .default(true),
  limit: z
    .preprocess((v) => {
      if (v === undefined) return undefined;
      if (typeof v === 'string' && v.trim() !== '') return Number(v);
      return v;
    }, z.number().int().min(1).max(50))
    .optional()
    .default(30),
  offset: z
    .preprocess((v) => {
      if (v === undefined) return undefined;
      if (typeof v === 'string' && v.trim() !== '') return Number(v);
      return v;
    }, z.number().int().min(0))
    .optional()
    .default(0)
});

module.exports = {
  shopItemsQuerySchema
};
