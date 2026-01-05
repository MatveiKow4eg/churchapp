const { z } = require('zod');

const purchaseBodySchema = z.object({
  itemKey: z.string().trim().min(1, 'itemKey is required').max(64)
});

module.exports = {
  purchaseBodySchema
};
