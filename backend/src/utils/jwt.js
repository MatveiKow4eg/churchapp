const jwt = require('jsonwebtoken');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

function signAccessToken({ userId, role, churchId }) {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    // keep consistent with auth middleware expectation
    throw new HttpError(401, 'UNAUTHORIZED', 'JWT_SECRET is not configured');
  }

  const payload = {
    // keep backward compatibility for authMiddleware/me
    sub: userId,

    // required by task: payload must contain userId/churchId/role
    userId,
    role,
    churchId: churchId ?? null
  };

  return jwt.sign(payload, secret, { algorithm: 'HS256', expiresIn: '7d' });
}

module.exports = {
  signAccessToken
};
