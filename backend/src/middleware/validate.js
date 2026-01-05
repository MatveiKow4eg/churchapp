const { ZodError } = require('zod');

/**
 * validate({ body?, query?, params? })
 *
 * Пример простого middleware для Zod-валидации.
 * - body/query/params при успехе заменяются на распарсенные значения
 * - при ошибке прокидывает ZodError в единый errorHandler
 */
function validate(schemas) {
  return (req, res, next) => {
    try {
      if (schemas.body) req.body = schemas.body.parse(req.body);
      if (schemas.query) req.query = schemas.query.parse(req.query);
      if (schemas.params) req.params = schemas.params.parse(req.params);
      return next();
    } catch (err) {
      // Пропускаем только ZodError, остальное — как есть
      if (err instanceof ZodError) return next(err);
      return next(err);
    }
  };
}

module.exports = { validate };
