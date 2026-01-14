const express = require('express');
const crypto = require('crypto');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { createChurchSchema } = require('../validators/churchSchemas');

const { prisma } = require('../db/prisma');
const { createChurch } = require('../services/churchService');
const { improveTaskText } = require('../services/aiTextService');

const router = express.Router();

function safeTextMeta(text) {
  const s = (text ?? '').toString();
  const preview = s.trim().slice(0, 40);
  const hash = crypto.createHash('sha256').update(s).digest('hex').slice(0, 12);
  return { len: s.length, hash, preview };
}

// In-memory simple rate limiter (per user+endpoint)
// Default: 10 req / 60s
const AI_RATE_LIMIT_WINDOW_MS = Number(process.env.AI_RATE_LIMIT_WINDOW_MS || 60_000);
const AI_RATE_LIMIT_MAX = Number(process.env.AI_RATE_LIMIT_MAX || 10);
const _aiBuckets = new Map();

function aiRateLimit(req, res, next) {
  const userId = req.user?.id || 'anon';
  const endpoint = req.originalUrl;
  const key = `${userId}:${endpoint}`;
  const now = Date.now();

  const bucket = _aiBuckets.get(key) || { count: 0, resetAt: now + AI_RATE_LIMIT_WINDOW_MS };

  if (now > bucket.resetAt) {
    bucket.count = 0;
    bucket.resetAt = now + AI_RATE_LIMIT_WINDOW_MS;
  }

  bucket.count += 1;
  _aiBuckets.set(key, bucket);

  if (bucket.count > AI_RATE_LIMIT_MAX) {
    return res.status(429).json({ error: { code: 'RATE_LIMIT', message: 'RATE_LIMIT' } });
  }

  return next();
}

function logAiRequest({ req, status, latencyMs, meta }) {
  const requestId = req.requestId || req.headers['x-request-id'] || '';
  const userId = req.user?.id || '';
  const endpoint = req.originalUrl;
  console.log(
    JSON.stringify({
      type: 'admin_ai',
      requestId,
      userId,
      endpoint,
      status,
      latencyMs,
      ...(meta ? { meta } : {})
    })
  );
}

// All /admin endpoints require ADMIN/SUPERADMIN
router.use(requireAuth);
router.use(requireAdmin);

// POST /admin/churches
// Access: SUPERADMIN
router.post('/churches', validate({ body: createChurchSchema }), async (req, res, next) => {
  try {
    const church = await createChurch(req.body);
    return res.status(201).json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        createdAt: church.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/churches
// Access: SUPERADMIN
router.get('/churches', async (req, res, next) => {
  try {
    const items = await prisma.church.findMany({
      orderBy: [{ createdAt: 'desc' }],
      select: { id: true, name: true, city: true, createdAt: true }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/users
// Access: SUPERADMIN
router.get('/users', async (req, res, next) => {
  try {
    const items = await prisma.user.findMany({
      orderBy: [{ createdAt: 'desc' }],
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarUpdatedAt: true,
        avatarConfig: true
      }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// PATCH /admin/users/:id
// Access: SUPERADMIN
router.patch('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, status, churchId, firstName, lastName } = req.body ?? {};

    const data = {};
    if (role !== undefined) data.role = role;
    if (status !== undefined) data.status = status;
    if (churchId !== undefined) data.churchId = churchId;
    if (firstName !== undefined) data.firstName = firstName;
    if (lastName !== undefined) data.lastName = lastName;

    if (Object.keys(data).length === 0) {
      return res.status(400).json({ code: 'BAD_REQUEST', message: 'No fields to update' });
    }

    const user = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarUpdatedAt: true,
        avatarConfig: true
      }
    });

    return res.json({ user });
  } catch (err) {
    return next(err);
  }
});

// POST /admin/ai/task-title-suggest
router.post('/ai/task-title-suggest', aiRateLimit, async (req, res, next) => {
  const startedAt = Date.now();
  const { text } = req.body ?? {};
  const meta = { input: safeTextMeta(text) };

  try {
    const prompt = [
      'Ты редактор заданий для мобильного приложения.',
      'Улучши ТОЛЬКО формулировку названия: не меняй смысл и НЕ добавляй новых требований.',
      'Верни 3–5 вариантов, каждый с новой строки, без нумерации, без кавычек, без комментариев.',
      '',
      `Название: ${(text ?? '').toString().trim()}`
    ].join('\n');

    const raw = await improveTaskText({ text: prompt, type: 'description' });

    const items = raw
      .split(/\r?\n+/)
      .map((s) => s.trim())
      .filter((s) => s.length > 0)
      .map((s) => s.replace(/^[\-•\*]+\s*/, '').trim())
      .filter((s) => s.length > 0);

    const variants = Array.from(new Set(items)).slice(0, 5);

    logAiRequest({
      req,
      status: 200,
      latencyMs: Date.now() - startedAt,
      meta: { ...meta, outCount: variants.length }
    });

    return res.json({ items: variants });
  } catch (err) {
    if (err && err.status && err.code) {
      const allow = new Set(['EMPTY_TEXT', 'RATE_LIMIT', 'HF_BAD_RESPONSE', 'HF_INFERENCE_FAILED']);
      const code = allow.has(err.code) ? err.code : 'HF_INFERENCE_FAILED';
      const status = code === 'EMPTY_TEXT' ? 400 : code === 'RATE_LIMIT' ? 429 : 502;

      logAiRequest({ req, status, latencyMs: Date.now() - startedAt, meta });
      return res.status(status).json({ error: { code, message: code } });
    }

    logAiRequest({ req, status: 500, latencyMs: Date.now() - startedAt, meta });
    return next(err);
  }
});

// POST /admin/ai/task-description-rewrite
router.post('/ai/task-description-rewrite', aiRateLimit, async (req, res, next) => {
  const startedAt = Date.now();
  const { text } = req.body ?? {};
  const meta = { input: safeTextMeta(text) };

  try {
    const improved = await improveTaskText({ text: text ?? '', type: 'description' });

    logAiRequest({ req, status: 200, latencyMs: Date.now() - startedAt, meta });

    return res.json({ text: improved });
  } catch (err) {
    if (err && err.status && err.code) {
      const allow = new Set(['EMPTY_TEXT', 'RATE_LIMIT', 'HF_BAD_RESPONSE', 'HF_INFERENCE_FAILED']);
      const code = allow.has(err.code) ? err.code : 'HF_INFERENCE_FAILED';
      const status = code === 'EMPTY_TEXT' ? 400 : code === 'RATE_LIMIT' ? 429 : 502;

      logAiRequest({ req, status, latencyMs: Date.now() - startedAt, meta });
      return res.status(status).json({ error: { code, message: code } });
    }

    logAiRequest({ req, status: 500, latencyMs: Date.now() - startedAt, meta });
    return next(err);
  }
});

module.exports = { adminRouter: router };
