const express = require('express');

const { translations, books, chapter, search, searchPreview, searchAll } = require('../controllers/bibleController');

const bibleRouter = express.Router();

// Public (no auth)
// GET /bible/translations
bibleRouter.get('/translations', translations);

// GET /bible/:translationId/books
bibleRouter.get('/:translationId/books', books);

// alias: /bible/search -> uses translationId=rus_syn
bibleRouter.get('/search', (req, res) => {
  // eslint-disable-next-line no-param-reassign
  req.params.translationId = 'rus_syn';
  return search(req, res);
});

// GET /bible/:translationId/search
bibleRouter.get('/:translationId/search', search);

// GET /bible/:translationId/search-preview
bibleRouter.get('/:translationId/search-preview', searchPreview);

// GET /bible/:translationId/search-all
bibleRouter.get('/:translationId/search-all', searchAll);

// GET /bible/:translationId/:bookId/:chapter
bibleRouter.get('/:translationId/:bookId/:chapter', chapter);

module.exports = { bibleRouter };
