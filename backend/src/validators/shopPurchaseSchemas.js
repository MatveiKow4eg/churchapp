const { z } = require('zod');

const purchaseBodySchema = z.object({
  // Accept both Prisma CUIDs and legacy ids used in seed/dev data (e.g. "shop_other_1").
  // The controller will still validate existence/ownership/active state.
  itemId: z.string().trim().min(1, 'itemId is required')
});

module.exports = {
  purchaseBodySchema
};
