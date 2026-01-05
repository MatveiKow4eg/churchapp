const { z } = require('zod');

const addToInventorySchema = z.object({
  itemId: z.string().cuid('Invalid itemId (expected cuid)')
});

module.exports = {
  addToInventorySchema
};
