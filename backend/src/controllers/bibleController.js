const bibleService = require('../services/bible.service');

function isServiceError(err) {
  return (
    err &&
    typeof err === 'object' &&
    Object.prototype.hasOwnProperty.call(err, 'status') &&
    Object.prototype.hasOwnProperty.call(err, 'code')
  );
}

function sendServiceError(res, err) {
  const { status, code, ...rest } = err;
  return res.status(status).json({ error: code, ...rest });
}

function clampInt(value, defaultValue, min, max) {
  const n = parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(n)) return defaultValue;
  return Math.min(max, Math.max(min, n));
}

async function translations(req, res) {
  try {
    const data = await bibleService.getTranslations();
    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

async function books(req, res) {
  try {
    const translationId = req.params.translationId;

    if (typeof translationId !== 'string' || translationId.length < 2 || translationId.length > 32) {
      return res.status(400).json({ error: 'INVALID_TRANSLATION_ID' });
    }

    if (!/^[a-z0-9_]+$/i.test(translationId)) {
      return res.status(400).json({ error: 'INVALID_TRANSLATION_ID' });
    }

    const data = await bibleService.getBooks(translationId);
    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

async function chapter(req, res) {
  try {
    const translationId = req.params.translationId;
    let bookId = req.params.bookId;
    const chapterNum = Number(req.params.chapter);

    if (typeof translationId !== 'string' || translationId.length < 2 || translationId.length > 32) {
      return res.status(400).json({ error: 'INVALID_TRANSLATION_ID' });
    }

    if (!/^[a-z0-9_]+$/i.test(translationId)) {
      return res.status(400).json({ error: 'INVALID_TRANSLATION_ID' });
    }

    if (typeof bookId !== 'string' || bookId.length < 1 || bookId.length > 32) {
      return res.status(400).json({ error: 'INVALID_BOOK_ID' });
    }

    bookId = bookId.toUpperCase();

    if (!Number.isInteger(chapterNum) || chapterNum <= 0) {
      return res.status(400).json({ error: 'INVALID_CHAPTER' });
    }

    const data = await bibleService.getChapter(translationId, bookId, chapterNum);
    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

async function search(req, res) {
  // Debug input (temporary)
  console.log('[bible] search req.params=', req.params);
  console.log('[bible] search req.query=', req.query);

  try {
    const translationId = req.params.translationId;

    const bookId = String(req.query.bookId || '').toUpperCase().trim();
    const q = String(req.query.q || '').trim();
    const limitRaw = req.query.limit;
    const limit = Math.min(200, Math.max(1, parseInt(limitRaw ?? '50', 10) || 50));

    const badRequest = () =>
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Invalid search params',
        details: { translationId, bookId, q, limit }
      });

    if (!translationId || typeof translationId !== 'string') {
      return badRequest();
    }

    if (!q || q.length < 2) {
      return badRequest();
    }

    if (!bookId || !/^[A-Z0-9]{2,5}$/.test(bookId)) {
      return badRequest();
    }

    console.log('[bible] search book=%s q="%s" limit=%d', bookId, q, limit);
    const data = await bibleService.searchInBook(translationId, bookId, q, limit);
    console.log('[bible] search done results=%d', data.results?.length ?? 0);

    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

async function searchPreview(req, res) {
  try {
    const translationId = req.params.translationId;
    const q = String(req.query.q || '').trim();
    const limit = clampInt(req.query.limit, 4, 1, 20);
    const timeBudgetMs = clampInt(req.query.timeBudgetMs, 1800, 200, 5000);

    if (q.length < 2) {
      return res.status(400).json({ error: 'BAD_REQUEST', message: 'q too short' });
    }

    const data = await bibleService.searchAllPreview(translationId, q, limit, timeBudgetMs);
    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

async function searchAll(req, res) {
  try {
    const translationId = req.params.translationId;
    const q = String(req.query.q || '').trim();

    if (q.length < 2) {
      return res.status(400).json({ error: 'BAD_REQUEST', message: 'q too short' });
    }

    const limit = clampInt(req.query.limit, 200, 1, 500);
    const timeBudgetMs = clampInt(req.query.timeBudgetMs, 15000, 1000, 60000);
    const offset = clampInt(req.query.offset, 0, 0, 1_000_000);

    const data = await bibleService.searchAll(translationId, q, limit, timeBudgetMs, offset);
    return res.json(data);
  } catch (err) {
    if (isServiceError(err)) return sendServiceError(res, err);
    return res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  translations,
  books,
  chapter,
  search,
  searchPreview,
  searchAll
};
