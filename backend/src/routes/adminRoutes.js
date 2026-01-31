const express = require('express');
const crypto = require('crypto');

const { requireAuth } = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validate');
const { createChurchSchema } = require('../validators/churchSchemas');
const { adminAdjustSchema } = require('../validators/pointsSchemas');
const pointsService = require('../services/pointsService');

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

// All /admin endpoints require ADMIN/SUPERADMIN/DEVELOPER
router.use(requireAuth);
router.use(requireAdmin);

// POST /admin/churches
// Access: SUPERADMIN/DEVELOPER
router.post('/churches', validate({ body: createChurchSchema }), async (req, res, next) => {
  try {
    const church = await createChurch(req.body);
    return res.status(201).json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        joinCode: church.joinCode,
        createdAt: church.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/churches
// Access: SUPERADMIN/DEVELOPER
router.get('/churches', async (req, res, next) => {
  try {
    const items = await prisma.church.findMany({
      where: { deletedAt: null },
      orderBy: [{ createdAt: 'desc' }],
      select: { id: true, name: true, city: true, joinCode: true, createdAt: true }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/churches/deleted
// Access: SUPERADMIN/DEVELOPER
router.get('/churches/deleted', async (req, res, next) => {
  try {
    const items = await prisma.church.findMany({
      where: { deletedAt: { not: null } },
      orderBy: [{ deletedAt: 'desc' }],
      take: 20,
      select: { id: true, name: true, city: true, joinCode: true, createdAt: true, deletedAt: true }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// POST /admin/churches/:id/restore
// Access: SUPERADMIN/DEVELOPER
router.post('/churches/:id/restore', async (req, res, next) => {
  try {
    const { id } = req.params;
    const church = await prisma.church.findUnique({
      where: { id },
      select: { id: true, deletedAt: true }
    });

    if (!church) {
      return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Church not found' } });
    }

    if (church.deletedAt == null) {
      return res.status(400).json({ error: { code: 'NOT_DELETED', message: 'Church is not deleted' } });
    }

    await prisma.church.update({
      where: { id },
      data: { deletedAt: null }
    });

    return res.status(200).json({ ok: true });
  } catch (err) {
    return next(err);
  }
});

// DELETE /admin/churches/:id
// Access: SUPERADMIN/DEVELOPER
// DANGER: deletes church and all related data (tasks, submissions, ledger, etc.)
router.delete('/churches/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { confirm } = req.body ?? {};

    if ((confirm ?? '').toString().trim().toLowerCase() !== 'удалить') {
      return res.status(400).json({ error: { code: 'CONFIRM_REQUIRED', message: 'Type "удалить" to confirm' } });
    }

    // Safety: forbid deleting the church you are currently scoped to.
    // This prevents nuking the active context and causing confusing client state.
    if (req.user?.churchId && req.user.churchId === id) {
      return res.status(400).json({
        error: {
          code: 'CANNOT_DELETE_ACTIVE_CHURCH',
          message: 'Cannot delete the church you are currently in'
        }
      });
    }

    const exists = await prisma.church.findUnique({
      where: { id },
      select: { id: true }
    });

    if (!exists) {
      return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Church not found' } });
    }

    // Soft-delete (move to "trash")
    await prisma.church.update({
      where: { id },
      data: { deletedAt: new Date() }
    });
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
});

// GET /admin/users
// Access: SUPERADMIN/DEVELOPER
// GET /admin/users
// Access: SUPERADMIN/DEVELOPER
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

// GET /admin/users/church
// Access: ADMIN+ (scoped by req.user.churchId)
router.get('/users/church', async (req, res, next) => {
  try {
    const churchId = req.user?.churchId;

    if (!churchId) {
      return res.status(409).json({ error: { code: 'NO_CHURCH', message: 'User has no church selected' } });
    }

    const items = await prisma.user.findMany({
      where: {
        churchId,
        status: 'ACTIVE'
      },
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarUpdatedAt: true,
        avatarConfig: true
      }
    });

    return res.json({ items });
  } catch (err) {
    return next(err);
  }
});

// GET /admin/users/:id/points
// Access: ADMIN+ (user must be in the same church)
router.get('/users/:id/points', async (req, res, next) => {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      return res.status(409).json({ error: { code: 'NO_CHURCH', message: 'User has no church selected' } });
    }

    const userId = req.params.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, churchId: true }
    });

    if (!user) {
      return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
    }

    if (user.churchId !== churchId) {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Forbidden' } });
    }

    const balance = await pointsService.getBalance(userId, churchId);

    return res.json({ userId, churchId, balance });
  } catch (err) {
    return next(err);
  }
});

// POST /admin/points/adjust
// Access: ADMIN+ (scoped by req.user.churchId)
// Body: { userId, amount (int, can be negative), reason }
router.post('/points/adjust', validate({ body: adminAdjustSchema }), async (req, res, next) => {
  try {
    const actorId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      return res.status(409).json({ error: { code: 'NO_CHURCH', message: 'User has no church selected' } });
    }

    const { userId, amount, reason } = req.body;

    await pointsService.addEntry({
      churchId,
      userId,
      type: 'ADMIN_ADJUSTMENT',
      amount,
      meta: {
        reason,
        actorId
      }
    });

    const balance = await pointsService.getBalance(userId, churchId);

    return res.status(201).json({ ok: true, userId, balance });
  } catch (err) {
    return next(err);
  }
});

// PATCH /admin/users/:id
// Access: SUPERADMIN/DEVELOPER
router.patch('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role, status, churchId, firstName, lastName } = req.body ?? {};

    const data = {};

    // SECURITY POLICY:
    // - DEVELOPER is the highest role.
    // - Only an existing DEVELOPER can grant/revoke the DEVELOPER role.
    // - SUPERADMIN can manage other roles, but cannot assign DEVELOPER.
    if (role !== undefined) {
      const requestedRole = (role ?? '').toString().trim().toUpperCase();
      const actorRole = (req.user?.role ?? '').toString().trim().toUpperCase();

      if (requestedRole === 'DEVELOPER' && actorRole !== 'DEVELOPER') {
        return res.status(403).json({
          error: {
            code: 'FORBIDDEN',
            message: 'Only DEVELOPER can assign DEVELOPER role'
          }
        });
      }

      // Prevent non-developers from demoting developers
      const target = await prisma.user.findUnique({ where: { id }, select: { role: true } });
      if (!target) {
        return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
      }
      const targetRole = (target.role ?? '').toString().trim().toUpperCase();
      if (targetRole === 'DEVELOPER' && actorRole !== 'DEVELOPER') {
        return res.status(403).json({
          error: {
            code: 'FORBIDDEN',
            message: 'Only DEVELOPER can change DEVELOPER role'
          }
        });
      }

      data.role = requestedRole;
    }

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

// DELETE /admin/users/:id
// Access: SUPERADMIN/DEVELOPER
router.delete('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Disallow deleting yourself to avoid locking out the only superadmin.
    if (req.user?.id === id) {
      return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Cannot delete yourself' } });
    }

    // Ensure user exists for predictable 404
    const exists = await prisma.user.findUnique({
      where: { id },
      select: { id: true }
    });

    if (!exists) {
      return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
    }

    // Hard delete. Related data is deleted by DB relations (onDelete: Cascade) where configured.
    await prisma.user.delete({ where: { id } });

    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
});

// POST /admin/impersonate
// Access: SUPERADMIN/DEVELOPER
// Switches SUPERADMIN/DEVELOPER context to a selected church.
// Also ensures the user is a "member" of that church by setting user.churchId
// (legacy single-church model).
// NOTE: once multi-church membership is introduced, this should write to ChurchMember
// instead of overwriting user.churchId.
router.post('/impersonate', async (req, res, next) => {
  try {
    const { churchId } = req.body ?? {};

    if (churchId == null || (churchId ?? '').toString().trim().isEmpty) {
      return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'churchId is required' } });
    }

    const church = await prisma.church.findUnique({
      where: { id: churchId.toString() },
      select: { id: true }
    });

    if (!church) {
      return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Church not found' } });
    }

    // Persist membership in DB (legacy: single church per user).
    // This makes the user a real participant (can submit tasks, etc.).
    await prisma.user.update({
      where: { id: req.user.id },
      data: { churchId: church.id }
    });

    const { signAccessToken } = require('../utils/jwt');

    const token = signAccessToken({
      userId: req.user.id,
      role: req.user.role,
      churchId: church.id
    });

    return res.json({ token, churchId: church.id });
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
