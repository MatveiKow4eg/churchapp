const { z } = require('zod');

// Common reusable schemas

const cuidSchema = z.string().cuid('Invalid id (expected cuid)');

module.exports = {
  cuidSchema
};
