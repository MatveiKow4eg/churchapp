const jwt = require('jsonwebtoken');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

function mapJwtErrorCode(code) {
  // Per requirement: error.code must be UNAUTHORIZED | FORBIDDEN.
  // Any token errors are mapped to UNAUTHORIZED.
  if (code === 'JWT_MISCONFIGURED') return 'UNAUTHORIZED';
  return 'UNAUTHORIZED';
}

async function requireAuth(req, res, next) {
  try {
    const header = req.headers['authorization'] || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throw new HttpError(401, 'UNAUTHORIZED', 'Missing or invalid Authorization header');
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      // Treat misconfiguration as auth failure for consistent client behavior
      throw new HttpError(401, 'JWT_MISCONFIGURED', 'JWT_SECRET is not configured');
    }

    let payload;
    try {
      payload = jwt.verify(token, secret, { algorithms: ['HS256'] });
    } catch (e) {
      throw new HttpError(401, 'INVALID_TOKEN', 'Token is invalid or expired');
    }

    // DEBUG (temporary)
    // eslint-disable-next-line no-console
    console.log(
      '[auth] path=',
      req.path,
      'auth=',
      (req.headers['authorization'] || '').slice(0, 30),
      'payloadRole=',
      payload.role,
      'payloadSub=',
      payload.sub ?? payload.userId
    );

    // payload: { sub, userId, role, churchId }
    // IMPORTANT: do NOT trust role from JWT blindly. It can be stale if user role
    // was updated after token issuance. Always resolve role from DB.
    const userId = payload.sub ?? payload.userId;

    const { prisma } = require('../db/prisma');
    const dbUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, churchId: true, status: true }
    });

    if (!dbUser) {
      throw new HttpError(401, 'UNAUTHORIZED', 'User not found');
    }

    if (dbUser.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'User is banned');
    }

    req.user = {
      id: dbUser.id,
      role: dbUser.role,
      churchId: dbUser.churchId ?? null
    };

    return next();
  } catch (err) {
    // Ensure error.code is strictly UNAUTHORIZED per spec
    if (err && err.status === 401) {
      err.code = mapJwtErrorCode(err.code);
      if (!err.message) err.message = 'Unauthorized';
    }
    return next(err);
  }
}

module.exports = {
  // New canonical name
  requireAuth,
  // Backward-compatible alias (do not break existing routes)
  authMiddleware: requireAuth
};
