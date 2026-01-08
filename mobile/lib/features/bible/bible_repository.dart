import 'package:flutter/foundation.dart';

import 'bible_api_client.dart';
import 'models/book.dart';
import 'models/bible_search.dart';
import 'models/chapter.dart';
import 'models/translation.dart';

class BibleRepository {
  BibleRepository({required BibleApiClient apiClient}) : _apiClient = apiClient;

  final BibleApiClient _apiClient;

  // Lightweight in-memory cache for parsed chapters.
  final Map<String, Chapter> _chapterCache = {};

  Future<Map<String, dynamic>> searchInBook({
    required String translationId,
    required String bookId,
    required String query,
    int limit = 50,
  }) {
    return _apiClient.searchInBook(
      translationId: translationId,
      bookId: bookId,
      query: query,
      limit: limit,
    );
  }

  Future<BibleSearchResponse> searchRusSynInBook({
    required String bookId,
    required String query,
    int limit = 50,
  }) async {
    final json = await _apiClient.searchInBook(
      translationId: 'rus_syn',
      bookId: bookId,
      query: query,
      limit: limit,
    );

    return BibleSearchResponse.fromJson(json);
  }

  Future<Translation> getRusSynTranslationsOrValidate() async {
    final raw = await _apiClient.getTranslations();

    final translations = raw
        .where((e) => e is Map)
        .map((e) => Translation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    try {
      return translations.firstWhere((t) => t.id == 'rus_syn');
    } catch (_) {
      throw Exception('Bible API: translation rus_syn not found in available translations');
    }
  }

  Future<List<Book>> getRusSynBooks() async {
    final raw = await _apiClient.getBooks('rus_syn');

    return raw
        .where((e) => e is Map)
        .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Chapter> getRusSynChapter(String bookId, int chapter) async {
    const translationId = 'rus_syn';
    final key = '$translationId:$bookId:$chapter';

    final cached = _chapterCache[key];
    if (cached != null) {
      return cached;
    }

    final json = await _apiClient.getChapter(translationId, bookId, chapter);

    // Temporary dev logging for real API structure (safe: keys + types only).
    if (kDebugMode && bookId == 'GEN' && chapter == 1) {
      debugPrint('[Bible API] GEN 1 top-level keys: ${json.keys.toList()}');

      void logNested(String label, dynamic v) {
        if (v is Map) {
          final m = Map<String, dynamic>.from(v);
          debugPrint('[Bible API] GEN 1 $label keys: ${m.keys.toList()}');

          // One more level for convenience.
          for (final key in m.keys) {
            final child = m[key];
            if (child is Map) {
              debugPrint(
                '[Bible API] GEN 1 $label.$key keys: ${Map<String, dynamic>.from(child).keys.toList()}',
              );
            } else {
              debugPrint('[Bible API] GEN 1 $label.$key type: ${child.runtimeType}');
            }
          }
        } else {
          debugPrint('[Bible API] GEN 1 $label type: ${v.runtimeType}');
        }
      }

      if (json.containsKey('data')) logNested('data', json['data']);
      if (json.containsKey('chapter')) logNested('chapter', json['chapter']);
      if (json.containsKey('verses')) logNested('verses', json['verses']);
      if (json.containsKey('text')) logNested('text', json['text']);
      if (json.containsKey('items')) logNested('items', json['items']);
    }

    final parsed = Chapter.fromJson(
      json,
      bookId: bookId,
      chapterNumber: chapter,
    );

    _chapterCache[key] = parsed;
    return parsed;
  }
}
