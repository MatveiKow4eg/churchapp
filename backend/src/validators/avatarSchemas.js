const { z } = require('zod');

function isHexColor(str) {
  if (typeof str !== 'string') return false;
  return /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(str);
}

const avatarUpdateSchema = z
  .object({
    version: z.literal(1),
    body: z.object({
      type: z.enum(['slim', 'normal', 'athletic', 'strong']),
      height: z.number().min(0).max(1),
      weight: z.number().min(0).max(1),
    }),
    skinTone: z.string().min(1),
    hair: z.object({
      style: z.string().min(1),
      color: z.string().refine(isHexColor, { message: 'INVALID_HEX_COLOR' }),
    }),
    face: z.object({
      preset: z.string().min(1),
    }),
    wear: z.object({
      top: z.string().optional(),
      bottom: z.string().optional(),
      shoes: z.string().optional(),
      accessory: z.string().optional(),
    }),
    external: z
      .object({
        provider: z.literal('readyplayerme'),
        avatarUrl: z.string().url(),
      })
      .optional(),
  })
  .refine((obj) => JSON.stringify(obj).length <= 20000, {
    message: 'AVATAR_CONFIG_TOO_LARGE',
  });

module.exports = { avatarUpdateSchema };
