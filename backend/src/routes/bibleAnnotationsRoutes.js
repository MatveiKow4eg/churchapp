const express = require('express');
const { requireAuth } = require('../middleware/authMiddleware');
const { listUserAnnotations, upsertUserAnnotations } = require('../services/bibleAnnotationsService');

const router = express.Router();

// GET /bible/annotations?translationId=rus_syn&bookId=GEN&chapter=1
router.get('/annotations', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const { translationId, bookId, chapter } = req.query;
    const rows = await listUserAnnotations(userId, { translationId, bookId, chapter });
    res.json({ items: rows });
  } catch (e) {
    next(e);
  }
});

// PUT /bible/annotations
// body: { items: [{translationId, bookId, chapter, verse, highlight?, isFavorite?, note?}, ...] }
router.put('/annotations', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const items = req.body?.items;
    const rows = await upsertUserAnnotations(userId, items);
    res.json({ items: rows });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
