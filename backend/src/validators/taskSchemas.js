const { z } = require('zod');

const taskCategorySchema = z.enum([
  'SPIRITUAL',
  'SERVICE',
  'COMMUNITY',
  'CREATIVITY',
  'REFLECTION',
  'QUIZ',
  'OTHER'
]);

const titleSchema = z
  .string()
  .trim()
  .min(3, 'Title must be at least 3 characters')
  .max(80, 'Title must be at most 80 characters');

const descriptionSchema = z
  .string()
  .trim()
  .min(10, 'Description must be at least 10 characters')
  .max(2000, 'Description must be at most 2000 characters');

const pointsRewardSchema = z
  .number()
  .int('pointsReward must be an integer')
  .min(1, 'pointsReward must be at least 1')
  .max(10000, 'pointsReward must be at most 10000');

const createTaskSchema = z.object({
  churchId: z.string().cuid('Invalid churchId (expected cuid)'),
  title: titleSchema,
  description: descriptionSchema,
  category: taskCategorySchema,
  pointsReward: pointsRewardSchema,
  createdById: z.string().cuid('Invalid createdById (expected cuid)').optional()
});

// Body schema for admin create task endpoint: churchId comes from req.user, not from client
// Quiz payload schemas
const quizOptionSchema = z.object({
  text: z.string().trim().min(1).max(500),
  isCorrect: z.boolean()
});

const quizQuestionSchema = z.object({
  text: z.string().trim().min(1).max(1000),
  multiSelect: z.boolean().optional().default(false),
  options: z.array(quizOptionSchema).min(2, 'Each question must have at least 2 options')
});

const quizSchema = z.object({
  shuffleQuestions: z.boolean().optional().default(false),
  maxAttempts: z.number().int().min(1).nullable().optional(),
  passScore: z.number().int().min(0).max(100).optional().default(70),
  questions: z.array(quizQuestionSchema).min(1, 'Quiz must contain at least 1 question')
});

const createTaskBodySchema = z.object({
  title: titleSchema,
  description: descriptionSchema,
  category: taskCategorySchema,
  pointsReward: pointsRewardSchema,
  quiz: z.union([quizSchema, z.undefined()]).optional()
});

const updateTaskSchema = z
  .object({
    churchId: z.string().cuid('Invalid churchId (expected cuid)').optional(),
    title: titleSchema.optional(),
    description: descriptionSchema.optional(),
    category: taskCategorySchema.optional(),
    pointsReward: pointsRewardSchema.optional(),
    createdById: z.string().cuid('Invalid createdById (expected cuid)').optional(),
    isActive: z.boolean().optional(),
    quiz: z
      .object({
        // For update, accept full snapshot to replace (server decides what is allowed)
        shuffleQuestions: z.boolean().optional(),
        maxAttempts: z.number().int().min(1).nullable().optional(),
        passScore: z.number().int().min(0).max(100).optional(),
        questions: z
          .array(
            z.object({
              text: z.string().trim().min(1).max(1000),
              multiSelect: z.boolean().optional(),
              options: z.array(
                z.object({ text: z.string().trim().min(1).max(500), isCorrect: z.boolean() })
              ).min(2)
            })
          )
          .min(1)
          .optional()
      })
      .optional()
  })
  .partial();

const listTasksQuerySchema = z.object({
  // churchId берём из токена (req.user), не из query
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
  category: taskCategorySchema.optional(),
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

const improveTaskTextBodySchema = z.object({
  title: z.string().trim().min(1).max(80),
  description: z.string().trim().min(1).max(2000)
});

module.exports = {
  taskCategorySchema,
  createTaskSchema,
  createTaskBodySchema,
  updateTaskSchema,
  listTasksQuerySchema,
  improveTaskTextBodySchema
};
