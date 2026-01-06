const { ZodError } = require('zod');

// Prisma errors (unique constraint, etc.)
let Prisma;
try {
  Prisma = require('@prisma/client');
} catch (_) {
  Prisma = null;
}

/**
 * Единый формат ошибки:
 * { error: { code, message, details? } }
 */
function errorHandler(err, req, res, next) {
  // Zod validation errors
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details: err.flatten()
      }
    });
  }

  // Prisma unique constraint (e.g. Church.name is unique)
  // Return 409 CONFLICT with required format
  if (Prisma && err instanceof Prisma.Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      return res.status(409).json({
        error: {
          code: 'CONFLICT',
          message: 'Church already exists'
        }
      });
    }
  }

  // Custom app errors
  if (err && err.code && err.message && err.status) {
    return res.status(err.status).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err.details ? { details: err.details } : {})
      }
    });
  }

  // Default
  console.error(err);
  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error'
    }
  });
}

// NOTE:
// We intentionally export only the middleware function.
// JSON formatting is handled by Express' res.json(); never manually stringify.

module.exports = { errorHandler };
