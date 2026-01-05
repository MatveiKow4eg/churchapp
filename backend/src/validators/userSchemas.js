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

const registerSchema = z.object({
  firstName: nameSchema,
  lastName: nameSchema,
  age: ageSchema,
  city: citySchema,
  email: z.string().trim().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters')
});

const joinChurchSchema = z.object({
  churchId: z.string().cuid('Invalid churchId (expected cuid)')
});

module.exports = {
  registerSchema,
  joinChurchSchema
};
