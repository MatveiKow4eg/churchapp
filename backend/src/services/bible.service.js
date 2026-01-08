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

// Helpers for robust verse extraction
function toPlainText(x) {
  if (x == null) return '';
  if (typeof x === 'string') return x;
  if (Array.isArray(x)) return x.map(toPlainText).join(' ').trim();
  if (typeof x === 'object') {
    if (typeof x.text === 'string') return x.text;
    if (typeof x.content === 'string') return x.content;
    if (Array.isArray(x.content)) return x.content.map(toPlainText).join(' ').trim();
    if (Array.isArray(x.items)) return x.items.map(toPlainText).join(' ').trim();
    if (typeof x.t === 'string') return x.t;
  }
  return String(x);
}

function parseVerseNumber(obj) {
  if (!obj || typeof obj !== 'object') return null;
  const candidates = [obj.verseNumber, obj.verse_number, obj.verse, obj.number, obj.v, obj.id];
  for (const c of candidates) {
    const n = typeof c === 'number' ? c : parseInt(String(c || ''), 10);
    if (Number.isFinite(n) && n > 0) return n;
  }
  return null;
}

function extractVersesFromChapter(chapterJson) {
  const content = chapterJson?.chapter?.content;
  if (!Array.isArray(content)) return [];

  const out = [];
  for (const item of content) {
    if (!item || typeof item !== 'object') continue;

    // Skip obvious non-verse types
    const type = item.type || item.kind;
    if (type === 'footnote' || type === 'footnotes') continue;

    const verse = parseVerseNumber(item);
    if (!verse) continue;

    const text = toPlainText(item.text ?? item.content ?? item.items ?? item.t);
    const cleaned = String(text || '').replace(/\s+/g, ' ').trim();
    if (!cleaned) continue;

    out.push({ verse, text: cleaned });
  }

  out.sort((a, b) => a.verse - b.verse);
  const dedup = [];
  const seen = new Set();
  for (const v of out) {
    if (seen.has(v.verse)) continue;
    seen.add(v.verse);
    dedup.push(v);
  }
  return dedup;
}

function determineMaxChapters(book) {
  if (!book) return 0;

  // 1) Primary numeric field for helloao
  if (Number.isInteger(book.chapters) && book.chapters > 0) {
    return book.chapters;
  }

  // 2) Alternative numeric fields
  if (Number.isInteger(book.numberOfChapters) && book.numberOfChapters > 0) {
    return book.numberOfChapters;
  }

  if (Number.isInteger(book.chaptersCount) && book.chaptersCount > 0) {
    return book.chaptersCount;
  }

  // 3) If array
  if (Array.isArray(book.chapters)) {
    return book.chapters.length;
  }

  // 4) Fallback — unknown
  return 0;
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
  const maxChapters = determineMaxChapters(book);

  const qLower = query.toLowerCase();
  const results = [];

  for (let ch = 1; ch <= maxChapters; ch++) {
    // eslint-disable-next-line no-await-in-loop
    const chapterJson = await getChapter(safeTranslationId, safeBookId, ch);

    const verses = extractVersesFromChapter(chapterJson);
    for (const v of verses) {
      const text = v.text;
      if (text.toLowerCase().includes(qLower)) {
        results.push({
          chapter: ch,
          verse: v.verse,
          text,
          ref: `${bookName} ${ch}:${v.verse}`
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

async function searchAllPreview(translationId, q, limit, timeBudgetMs) {
  const t0 = Date.now();
  const safeTranslationId = String(translationId);

  const booksJson = await getBooks(safeTranslationId);
  const books = normalizeBooksPayload(booksJson);

  const results = [];
  const needle = String(q).toLowerCase();

  // 1) Build book metas and global max chapters
  const metasRaw = await Promise.all(
    books.map(async (b) => {
      const bookIdRaw = (b && (b.id || b.bookId || b.abbr || b.code)) ?? '';
      const bookId = String(bookIdRaw).toUpperCase();
      if (!bookId) return null;

      const bookName = b && (b.name || b.title || b.longName);
      const maxChapters = determineMaxChapters(b);

      return { bookId, bookName: bookName ? String(bookName) : undefined, maxChapters: Number(maxChapters) || 0 };
    })
  );

  const bookMetas = metasRaw.filter((m) => m && m.maxChapters > 0);

  console.log(
    '[bible] preview bookMetas sample:',
    bookMetas.slice(0, 5).map((b) => ({ bookId: b.bookId, maxChapters: b.maxChapters }))
  );

  const globalMax = bookMetas.length > 0 ? Math.max(...bookMetas.map((m) => m.maxChapters)) : 0;

  let scannedChapters = 0;
  const touchedBooks = new Set();

  function finish(truncated) {
    const elapsedMs = Date.now() - t0;
    const scannedBooksTouched = touchedBooks.size;
    console.log(
      '[bible] preview done q="%s" results=%d elapsedMs=%d scannedChapters=%d scannedBooks=%d truncated=%s',
      q,
      results.length,
      elapsedMs,
      scannedChapters,
      scannedBooksTouched,
      String(truncated)
    );

    return {
      translationId: safeTranslationId,
      query: String(q),
      total: results.length,
      results,
      meta: {
        elapsedMs,
        timeBudgetMs,
        truncated,
        scannedChapters,
        scannedBooksTouched,
        strategy: 'breadth-first',
      },
    };
  }

  // 2) Breadth-first scanning by chapter index across all books
  for (let ch = 1; ch <= globalMax; ch++) {
    for (const bm of bookMetas) {
      if (Date.now() - t0 > timeBudgetMs) return finish(true);
      if (results.length >= limit) return finish(true);

      if (ch > bm.maxChapters) continue;

      let chapterJson;
      try {
        // eslint-disable-next-line no-await-in-loop
        chapterJson = await getChapter(safeTranslationId, bm.bookId, ch);
      } catch (err) {
        // If chapter fetch fails here, consider it as end-of-book or transient; skip.
        continue;
      }

      scannedChapters += 1;
      touchedBooks.add(bm.bookId);

      if (bm.bookId === 'GEN' && ch === 1) {
        const verses = extractVersesFromChapter(chapterJson);
        console.log('[bible] GEN1 extracted verses=', verses.length, 'sample=', verses[0]?.text?.slice(0, 60));
      }

      if (Date.now() - t0 > timeBudgetMs) return finish(true);

      const verses = extractVersesFromChapter(chapterJson);
      for (const v of verses) {
        const text = v.text;
        if (text.toLowerCase().includes(needle)) {
          results.push({
            bookId: bm.bookId,
            bookName: bm.bookName,
            chapter: ch,
            verse: v.verse,
            text,
            ref: `${bm.bookName ? bm.bookName : bm.bookId} ${ch}:${v.verse}`,
          });

          if (results.length >= limit) {
            return finish(true);
          }
        }
      }
    }
  }

  return finish((Date.now() - t0 > timeBudgetMs) || (results.length >= limit));
}

async function searchAll(translationId, q, limit, timeBudgetMs, offset) {
  const t0 = Date.now();
  const safeTranslationId = String(translationId);
  const qLower = String(q).toLowerCase();
  const lim = Math.max(1, Math.min(Number(limit) || 200, 500));
  const off = Math.max(0, Math.min(Number(offset) || 0, 1_000_000));

  const booksJson = await getBooks(safeTranslationId);
  const books = normalizeBooksPayload(booksJson);

  const metasRaw = await Promise.all(
    books.map(async (b) => {
      const bookIdRaw = (b && (b.id || b.bookId || b.abbr || b.code)) ?? '';
      const bookId = String(bookIdRaw).toUpperCase();
      if (!bookId) return null;
      const bookName = b && (b.name || b.title || b.longName);
      const maxChapters = determineMaxChapters(b);
      return { bookId, bookName: bookName ? String(bookName) : undefined, maxChapters: Number(maxChapters) || 0 };
    })
  );

  const bookMetas = metasRaw.filter((m) => m && m.maxChapters > 0);
  const globalMax = bookMetas.length > 0 ? Math.max(...bookMetas.map((m) => m.maxChapters)) : 0;

  let scannedChapters = 0;
  const touchedBooks = new Set();

  const results = [];
  let skipped = 0;

  function finish(truncated) {
    const elapsedMs = Date.now() - t0;
    const scannedBooksTouched = touchedBooks.size;
    const total = truncated ? off + results.length : off + results.length;
    console.log(
      '[bible] search-all done q="%s" returned=%d offset=%d truncated=%s scannedChapters=%d',
      q,
      results.length,
      off,
      String(truncated),
      scannedChapters
    );

    return {
      translationId: safeTranslationId,
      query: String(q),
      total,
      results,
      meta: {
        elapsedMs,
        timeBudgetMs,
        truncated,
        scannedChapters,
        scannedBooksTouched,
        strategy: 'breadth-first',
      },
    };
  }

  for (let ch = 1; ch <= globalMax; ch++) {
    for (const bm of bookMetas) {
      if (Date.now() - t0 > timeBudgetMs) return finish(true);
      if (results.length >= lim) return finish(true);
      if (ch > bm.maxChapters) continue;

      let chapterJson;
      try {
        // eslint-disable-next-line no-await-in-loop
        chapterJson = await getChapter(safeTranslationId, bm.bookId, ch);
      } catch (err) {
        continue;
      }

      scannedChapters += 1;
      touchedBooks.add(bm.bookId);

      const verses = extractVersesFromChapter(chapterJson);
      for (const v of verses) {
        const text = v.text;
        if (text.toLowerCase().includes(qLower)) {
          if (skipped < off) {
            skipped += 1;
            continue;
          }

          results.push({
            bookId: bm.bookId,
            bookName: bm.bookName,
            chapter: ch,
            verse: v.verse,
            text,
            ref: `${bm.bookName ? bm.bookName : bm.bookId} ${ch}:${v.verse}`,
          });

          if (results.length >= lim) return finish(true);
        }
      }
    }
  }

  return finish((Date.now() - t0 > timeBudgetMs) || (results.length >= lim));
}

module.exports = {
  getTranslations,
  getBooks,
  getChapter,
  searchInBook,
  searchAllPreview,
  searchAll,

  // exported for tests/debug
  getCached,
  setCached
};
