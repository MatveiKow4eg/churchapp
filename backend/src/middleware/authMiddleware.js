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

function requireAuth(req, res, next) {
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
    req.user = {
      id: payload.sub ?? payload.userId,
      role: payload.role,
      churchId: payload.churchId ?? null
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
