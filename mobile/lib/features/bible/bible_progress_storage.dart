import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BibleLastPosition {
  const BibleLastPosition({
    required this.bookId,
    required this.chapter,
    required this.savedAt,
    this.bookName,
  });

  final String bookId;
  final int chapter;
  final String? bookName;
  final int savedAt;
}

class BibleProgressStorage {
  BibleProgressStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kBookId = 'bible.last.bookId';
  static const _kChapter = 'bible.last.chapter';
  static const _kBookName = 'bible.last.bookName';
  static const _kSavedAt = 'bible.last.savedAt';

  Future<void> saveLastPosition({
    required String bookId,
    required int chapter,
    required String? bookName,
  }) async {
    await _storage.write(key: _kBookId, value: bookId);
    await _storage.write(key: _kChapter, value: chapter.toString());
    await _storage.write(key: _kBookName, value: bookName);
    await _storage.write(
      key: _kSavedAt,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<BibleLastPosition?> loadLastPosition() async {
    final bookId = await _storage.read(key: _kBookId);
    final chapterStr = await _storage.read(key: _kChapter);

    if (bookId == null || bookId.trim().isEmpty) return null;
    final chapter = int.tryParse(chapterStr ?? '');
    if (chapter == null || chapter <= 0) return null;

    final bookName = await _storage.read(key: _kBookName);
    final savedAtStr = await _storage.read(key: _kSavedAt);
    final savedAt = int.tryParse(savedAtStr ?? '') ?? 0;

    return BibleLastPosition(
      bookId: bookId,
      chapter: chapter,
      bookName: (bookName == null || bookName.trim().isEmpty) ? null : bookName,
      savedAt: savedAt,
    );
  }

  Future<void> clearLastPosition() async {
    await _storage.delete(key: _kBookId);
    await _storage.delete(key: _kChapter);
    await _storage.delete(key: _kBookName);
    await _storage.delete(key: _kSavedAt);
  }
}
