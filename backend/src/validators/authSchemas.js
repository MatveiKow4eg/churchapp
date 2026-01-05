const { z } = require('zod');

const loginSchema = z.object({
  email: z.string().trim().email('Invalid email'),
  password: z.string().min(1, 'Password is required')
});

module.exports = {
  loginSchema
};
