const DEFAULT_BASE_URL = 'https://bible.helloao.org';

/**
 * @typedef {{ expiresAt: number; data: any }} CacheEntry
 */

/** @type {Map<string, CacheEntry>} */
const cache = new Map();

function getCached(key) {
  const entry = cache.get(key);
  if (!entry) return null;

  if (Date.now() >= entry.expiresAt) {
    cache.delete(key);
    return null;
  }

  console.log(`[bible] cache hit key=${key}`);
  return entry.data;
}

function setCached(key, data, ttlMs) {
  cache.set(key, { expiresAt: Date.now() + ttlMs, data });
}

function buildUrl(pathname) {
  const base = process.env.BIBLE_PROXY_BASE_URL || DEFAULT_BASE_URL;
  return `${base.replace(/\/$/, '')}${pathname}`;
}

async function fetchJson(url) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10_000);

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: controller.signal
    });

    if (!res.ok) {
      console.log(`[bible] upstream GET ${url} status=${res.status} cache=miss`);
      throw { status: 502, code: 'BIBLE_UPSTREAM_BAD_STATUS', upstreamStatus: res.status };
    }

    console.log(`[bible] upstream GET ${url} status=${res.status} cache=miss`);
    return await res.json();
  } catch (err) {
    // Timeout
    if (err && (err.name === 'AbortError' || err.code === 'ABORT_ERR')) {
      throw { status: 504, code: 'BIBLE_TIMEOUT' };
    }

    // DNS / network / other fetch error
    throw { status: 502, code: 'BIBLE_UPSTREAM_ERROR' };
  } finally {
    clearTimeout(timeoutId);
  }
}

async function fetchJsonWithCache(key, url, ttlMs) {
  const cached = getCached(key);
  if (cached) return cached;

  const data = await fetchJson(url);
  setCached(key, data, ttlMs);
  return data;
}

const TTL_TRANSLATIONS_MS = 24 * 60 * 60 * 1000;
const TTL_BOOKS_MS = 24 * 60 * 60 * 1000;
const TTL_CHAPTER_MS = 10 * 60 * 1000;

async function getTranslations() {
  const url = buildUrl('/api/available_translations.json');
  const key = `translations`;
  return fetchJsonWithCache(key, url, TTL_TRANSLATIONS_MS);
}

async function getBooks(translationId) {
  const safeTranslationId = String(translationId);
  const url = buildUrl(`/api/${encodeURIComponent(safeTranslationId)}/books.json`);
  const key = `books:${safeTranslationId}`;
  return fetchJsonWithCache(key, url, TTL_BOOKS_MS);
}

async function getChapter(translationId, bookId, chapter) {
  const safeTranslationId = String(translationId);
  const safeBookId = String(bookId);
  const safeChapter = Number(chapter);

  const url = buildUrl(
    `/api/${encodeURIComponent(safeTranslationId)}/${encodeURIComponent(safeBookId)}/${encodeURIComponent(
      String(safeChapter)
    )}.json`
  );

  const key = `chapter:${safeTranslationId}:${safeBookId}:${safeChapter}`;
  return fetchJsonWithCache(key, url, TTL_CHAPTER_MS);
}

function normalizeBooksPayload(booksJson) {
  // Upstream may return either array or { books: [...] }
  if (Array.isArray(booksJson)) return booksJson;
  if (booksJson && Array.isArray(booksJson.books)) return booksJson.books;
  return [];
}

function inferChaptersCount(book) {
  if (!book || typeof book !== 'object') return null;

  const candidates = [book.numberOfChapters, book.chaptersCount];
  for (const x of candidates) {
    const n = Number(x);
    if (Number.isInteger(n) && n > 0) return n;
  }

  // Some APIs provide `chapters` as an array of chapter links/objects.
  if (Array.isArray(book.chapters) && book.chapters.length > 0) {
    return book.chapters.length;
  }

  // Generic fallback: any array-ish property that looks like chapter links.
  for (const [k, v] of Object.entries(book)) {
    if (/chapters?/i.test(k) && Array.isArray(v) && v.length > 0) {
      return v.length;
    }
  }

  return null;
}

function extractVerseText(contentAny) {
  if (contentAny == null) return '';
  if (typeof contentAny === 'string') return contentAny;

  // If content is a list of strings / objects with text.
  if (Array.isArray(contentAny)) {
    return contentAny
      .map((x) => {
        if (x == null) return '';
        if (typeof x === 'string') return x;
        if (typeof x === 'object') {
          // common shapes: { text: '...' } / { content: [...] }
          if (typeof x.text === 'string') return x.text;
          if (typeof x.content === 'string') return x.content;
          if (Array.isArray(x.content)) return extractVerseText(x.content);
        }
        return '';
      })
      .join('')
      .trim();
  }

  if (typeof contentAny === 'object') {
    if (typeof contentAny.text === 'string') return contentAny.text;
    if (typeof contentAny.content === 'string') return contentAny.content;
    if (Array.isArray(contentAny.content)) return extractVerseText(contentAny.content);
  }

  return '';
}

async function determineMaxChapters({ translationId, bookId, book, maxProbe = 200 }) {
  const fromBooks = inferChaptersCount(book);
  if (fromBooks) return fromBooks;

  // Fallback: probe chapter endpoints until upstream fails.
  // IMPORTANT: limit probes to avoid overload.
  for (let ch = 1; ch <= maxProbe; ch++) {
    try {
      // eslint-disable-next-line no-await-in-loop
      await getChapter(translationId, bookId, ch);
    } catch (err) {
      // If upstream returns non-ok, our fetchJson throws 502 without exposing status.
      // We treat the first failure as end-of-book (best-effort fallback).
      return ch - 1;
    }
  }

  return maxProbe;
}

async function searchInBook(translationId, bookId, q, limit) {
  const safeTranslationId = String(translationId);
  const safeBookId = String(bookId).toUpperCase();
  const query = String(q);
  const lim = Math.max(1, Math.min(Number(limit) || 50, 200));

  const booksJson = await getBooks(safeTranslationId);
  const books = normalizeBooksPayload(booksJson);

  const book = books.find((b) => {
    const id = (b && (b.id || b.bookId || b.abbr || b.code)) ?? '';
    return String(id).toUpperCase() === safeBookId;
  });

  if (!book) {
    throw { status: 404, code: 'BIBLE_BOOK_NOT_FOUND', bookId: safeBookId };
  }

  const bookName = String(book.name || book.title || book.longName || safeBookId);
  const maxChapters = await determineMaxChapters({
    translationId: safeTranslationId,
    bookId: safeBookId,
    book
  });

  const qLower = query.toLowerCase();
  const results = [];

  for (let ch = 1; ch <= maxChapters; ch++) {
    // eslint-disable-next-line no-await-in-loop
    const chapterJson = await getChapter(safeTranslationId, safeBookId, ch);
    const content = chapterJson?.chapter?.content;
    if (!Array.isArray(content)) continue;

    for (const el of content) {
      const verseNumber = el?.verseNumber;
      const verseNum = Number(verseNumber);
      if (!Number.isInteger(verseNum) || verseNum <= 0) continue;

      const text = extractVerseText(el?.content);
      if (!text) continue;

      if (text.toLowerCase().includes(qLower)) {
        results.push({
          chapter: ch,
          verse: verseNum,
          text,
          ref: `${bookName} ${ch}:${verseNum}`
        });
        if (results.length >= lim) break;
      }
    }

    if (results.length >= lim) break;
  }

  return {
    translationId: safeTranslationId,
    bookId: safeBookId,
    query,
    total: results.length,
    results
  };
}

module.exports = {
  getTranslations,
  getBooks,
  getChapter,
  searchInBook,

  // exported for tests/debug
  getCached,
  setCached
};
