import { Router } from 'express';
import { bibleController } from '../controllers/bible.controller';

const router = Router();

// public (no auth)
router.get('/translations', bibleController.translations);

// alias: /bible/search -> uses translationId=rus_syn
router.get('/search', (req, res) => {
  // eslint-disable-next-line no-param-reassign
  req.params.translationId = 'rus_syn';
  return bibleController.search(req, res);
});

router.get('/:translationId/books', bibleController.books);
router.get('/:translationId/search', bibleController.search);
router.get('/:translationId/:bookId/:chapter', bibleController.chapter);

export default router;
