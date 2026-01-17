const { prisma } = require('../db/prisma');

function normalizeTranslationId(v) {
  return (v ?? '').toString().trim().toLowerCase();
}

function normalizeBookId(v) {
  return (v ?? '').toString().trim().toUpperCase();
}

function toInt(v) {
  const n = typeof v === 'number' ? v : parseInt((v ?? '').toString(), 10);
  return Number.isFinite(n) ? n : NaN;
}

function normalizeHighlight(v) {
  if (v == null) return null;
  const s = v.toString().trim().toLowerCase();
  if (!s) return null;
  const allowed = new Set(['yellow', 'green', 'blue', 'pink', 'purple']);
  return allowed.has(s) ? s : null;
}

function isEmptyAnnotation({ highlight, isFavorite, note }) {
  const noteNorm = (note ?? '').toString().trim();
  return highlight == null && !isFavorite && noteNorm.length === 0;
}

async function listUserAnnotations(userId, { translationId, bookId, chapter } = {}) {
  const where = { userId };
  if (translationId) where.translationId = normalizeTranslationId(translationId);
  if (bookId) where.bookId = normalizeBookId(bookId);
  if (chapter != null) {
    const ch = toInt(chapter);
    if (Number.isFinite(ch)) where.chapter = ch;
  }

  const rows = await prisma.bibleVerseAnnotation.findMany({
    where,
    orderBy: [{ updatedAt: 'desc' }],
  });

  return rows;
}

async function upsertUserAnnotations(userId, items) {
  if (!Array.isArray(items)) {
    const err = new Error('items must be an array');
    err.status = 400;
    err.code = 'VALIDATION_ERROR';
    throw err;
  }

  const now = new Date();

  const ops = [];
  for (const raw of items) {
    const translationId = normalizeTranslationId(raw.translationId);
    const bookId = normalizeBookId(raw.bookId);
    const chapter = toInt(raw.chapter);
    const verse = toInt(raw.verse);

    if (!translationId || !bookId || !Number.isFinite(chapter) || !Number.isFinite(verse)) {
      const err = new Error('Invalid ref in items');
      err.status = 400;
      err.code = 'VALIDATION_ERROR';
      throw err;
    }

    const highlight = normalizeHighlight(raw.highlight);
    const isFavorite = raw.isFavorite === true;
    const note = raw.note == null ? null : raw.note.toString();

    const empty = isEmptyAnnotation({ highlight, isFavorite, note });

    const where = {
      userId_translationId_bookId_chapter_verse: {
        userId,
        translationId,
        bookId,
        chapter,
        verse,
      },
    };

    if (empty) {
      // Delete if exists, ignore if missing.
      ops.push(
        prisma.bibleVerseAnnotation.delete({ where }).catch(() => null),
      );
      continue;
    }

    ops.push(
      prisma.bibleVerseAnnotation.upsert({
        where,
        create: {
          userId,
          translationId,
          bookId,
          chapter,
          verse,
          highlight,
          isFavorite,
          note,
          updatedAt: now,
        },
        update: {
          highlight,
          isFavorite,
          note,
          updatedAt: now,
        },
      }),
    );
  }

  const results = await prisma.$transaction(ops);
  // Filter out nulls (from delete ignore)
  return results.filter(Boolean);
}

module.exports = {
  listUserAnnotations,
  upsertUserAnnotations,
};
