import 'package:flutter/foundation.dart';

import 'verse.dart';

class Chapter {
  const Chapter({
    required this.bookId,
    required this.chapterNumber,
    required this.verses,
    required this.rawJson,
  });

  final String bookId;
  final int chapterNumber;
  final List<Verse> verses;

  /// Keeps the original payload for forward compatibility.
  final Map<String, dynamic> rawJson;

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    required String bookId,
    required int chapterNumber,
  }) {
    List<Verse> parseList(dynamic listAny) {
      if (listAny is! List) return const [];
      final out = <Verse>[];
      for (final item in listAny) {
        final v = Verse.tryParse(item);
        if (v == null) continue;
        if (v.text.trim().isEmpty) continue;
        out.add(v);
      }
      out.sort((a, b) => a.number.compareTo(b.number));
      return out;
    }

    List<Verse> parseMapNumberToText(dynamic mapAny) {
      if (mapAny is! Map) return const [];
      final map = Map<String, dynamic>.from(mapAny);
      final out = <Verse>[];
      for (final entry in map.entries) {
        final num = int.tryParse(entry.key.toString());
        if (num == null) continue;
        final text = entry.value is String
            ? (entry.value as String).trim()
            : (entry.value?.toString() ?? '').trim();
        if (text.isEmpty) continue;
        out.add(Verse(number: num, text: text, rawJson: const {}));
      }
      out.sort((a, b) => a.number.compareTo(b.number));
      return out;
    }

    Map<String, dynamic>? mapAt(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    List<Verse> verses = const [];

    // Priority order.
    verses = parseList(json['verses']);

    if (verses.isEmpty) {
      final chapter = mapAt(json['chapter']);
      if (chapter != null && chapter['content'] is List) {
        final list = chapter['content'] as List;

        final out = <Verse>[];
        for (final item in list) {
          // content may include headings/paragraphs/etc.
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final type = (m['type'] ?? m['kind'])?.toString();

            final hasVerseNumber = m.containsKey('verseNumber') ||
                m.containsKey('verse_number') ||
                m.containsKey('verse') ||
                m.containsKey('number') ||
                m.containsKey('v');

            // Parse only explicit verses, or anything that looks like a verse.
            if (type != null && type != 'verse' && !hasVerseNumber) {
              continue;
            }
          }

          final v = Verse.tryParse(item);
          if (v != null) out.add(v);
        }

        out.sort((a, b) => a.number.compareTo(b.number));

        // Deduplicate by verse number (keep first).
        final seen = <int>{};
        final deduped = <Verse>[];
        for (final v in out) {
          if (seen.add(v.number)) deduped.add(v);
        }

        verses = deduped;
      }
    }

    if (verses.isEmpty) {
      final data = mapAt(json['data']);
      if (data != null) verses = parseList(data['verses']);
    }

    if (verses.isEmpty) {
      final chapter = mapAt(json['chapter']);
      if (chapter != null) verses = parseList(chapter['verses']);
    }

    if (verses.isEmpty) {
      verses = parseList(json['items']);
    }

    if (verses.isEmpty) {
      // Some APIs expose full chapter text as a map {"1": "...", "2": "..."}
      verses = parseMapNumberToText(json['text']);
    }

    if (verses.isEmpty) {
      // Or verses itself can be a map {"1": "..."}
      verses = parseMapNumberToText(json['verses']);
    }

    // Debug: inspect real helloao structure for GEN 1 (safe logging: type + keys only).
    if (kDebugMode && bookId == 'GEN' && chapterNumber == 1) {
      final chapter = json['chapter'];
      if (chapter is Map && chapter['content'] is List) {
        final first = (chapter['content'] as List).first;
        debugPrint(
          '[Bible API] GEN1 chapter.content[0] type=${first.runtimeType} keys=${first is Map ? (first as Map).keys.toList() : ''}',
        );
      }
    }

    return Chapter(
      bookId: bookId,
      chapterNumber: chapterNumber,
      verses: verses,
      rawJson: json,
    );
  }
}
