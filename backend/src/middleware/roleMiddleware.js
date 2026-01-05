class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

/**
 * requireRole(...roles)
 *
 * Usage:
 *   router.post('/admin-only', requireAuth, requireRole('ADMIN', 'SUPERADMIN'), handler)
 */
function requireRole(...roles) {
  const allowed = roles.flat();

  return (req, res, next) => {
    try {
      if (!req.user || !req.user.role) {
        // If route forgot requireAuth, behave as UNAUTHORIZED.
        throw new HttpError(401, 'UNAUTHORIZED', 'Unauthorized');
      }

      if (!allowed.includes(req.user.role)) {
        throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
      }

      return next();
    } catch (err) {
      return next(err);
    }
  };
}

/**
 * requireAdmin
 * Alias for requireRole('ADMIN', 'SUPERADMIN')
 */
const requireAdmin = requireRole('ADMIN', 'SUPERADMIN');

/**
 * requireSameChurch
 *
 * - SUPERADMIN: always allowed
 * - Otherwise compares req.user.churchId with:
 *   - req.params.churchId OR
 *   - req.body.churchId (if params absent)
 */
function requireSameChurch(req, res, next) {
  try {
    if (!req.user) {
      throw new HttpError(401, 'UNAUTHORIZED', 'Unauthorized');
    }

    if (req.user.role === 'SUPERADMIN') {
      return next();
    }

    const userChurchId = req.user.churchId ?? null;
    const targetChurchId =
      (req.params && req.params.churchId) ||
      (req.body && req.body.churchId) ||
      null;

    // If endpoint is church-scoped, but churchId not provided, deny.
    if (!userChurchId || !targetChurchId || userChurchId !== targetChurchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  requireRole,
  requireAdmin,
  requireSameChurch
};
