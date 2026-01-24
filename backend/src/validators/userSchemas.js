const { z } = require('zod');

const nameSchema = z
  .string()
  .trim()
  .min(2, 'Must be at least 2 characters');

const citySchema = z
  .string()
  .trim()
  .min(2, 'Must be at least 2 characters');

// Дефолтный диапазон для MVP из задачи.
// Если позже потребуется — вынесем в конфиг.
const ageSchema = z
  .number()
  .int('Must be an integer')
  .min(6, 'Minimum age is 6')
  .max(30, 'Maximum age is 30');

const usernameSchema = z
  .string()
  .trim()
  .min(3, 'Username must be at least 3 characters')
  .max(20, 'Username must be at most 20 characters')
  .regex(/^[a-zA-Z0-9_.]+$/, 'Username may contain only letters, numbers, _ and .');

const emailSchema = z.string().trim().email('Invalid email');

const registerSchema = z
  .object({
    firstName: nameSchema,
    lastName: nameSchema,
    age: ageSchema,
    city: citySchema,
    // Either email or username is required.
    email: emailSchema.optional(),
    username: usernameSchema.optional(),
    password: z.string().min(6, 'Password must be at least 6 characters')
  })
  .refine((data) => !!data.email || !!data.username, {
    message: 'Either email or username is required',
    path: ['email']
  })
  .refine((data) => !(data.email && data.username), {
    message: 'Provide either email or username (not both)',
    path: ['email']
  });

const joinChurchSchema = z.object({
  churchId: z.string().cuid('Invalid churchId (expected cuid)')
});

module.exports = {
  registerSchema,
  joinChurchSchema
};
