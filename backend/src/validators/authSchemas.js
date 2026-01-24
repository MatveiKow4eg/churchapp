const { z } = require('zod');

const loginSchema = z.object({
  // Can be either email or username.
  identifier: z.string().trim().min(1, 'Email or username is required'),
  password: z.string().min(1, 'Password is required')
});

module.exports = {
  loginSchema
};
