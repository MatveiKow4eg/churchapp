import 'dart:convert';

/// A structured reference to a Bible passage.
///
/// This is stored client-side and currently serialized into Task.description
/// (because backend Task model does not yet support explicit fields).
///
/// Once backend adds a JSON field, we can send this structure directly.
class BibleRef {
  const BibleRef({
    required this.translationId,
    required this.bookId,
    required this.bookName,
    required this.fromChapter,
    this.fromVerse,
    this.toChapter,
    this.toVerse,
  });

  final String translationId; // e.g. "rus_syn"
  final String bookId; // e.g. "GEN"
  final String bookName; // e.g. "Бытие"

  final int fromChapter;
  final int? fromVerse;

  final int? toChapter;
  final int? toVerse;

  Map<String, dynamic> toJson() => {
        'translationId': translationId,
        'bookId': bookId,
        'bookName': bookName,
        'fromChapter': fromChapter,
        if (fromVerse != null) 'fromVerse': fromVerse,
        if (toChapter != null) 'toChapter': toChapter,
        if (toVerse != null) 'toVerse': toVerse,
      };

  factory BibleRef.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return BibleRef(
      translationId: (json['translationId'] as String?) ?? 'rus_syn',
      bookId: (json['bookId'] as String?) ?? '',
      bookName: (json['bookName'] as String?) ?? '',
      fromChapter: asInt(json['fromChapter']) ?? 1,
      fromVerse: asInt(json['fromVerse']),
      toChapter: asInt(json['toChapter']),
      toVerse: asInt(json['toVerse']),
    );
  }

  String toDisplayString() {
    final from = _formatPart(fromChapter, fromVerse);
    final to = (toChapter == null && toVerse == null)
        ? null
        : _formatPart(toChapter ?? fromChapter, toVerse);

    if (to == null || to == from) return '$bookName $from';

    // If same book, show as "Бытие 1:1–2:3".
    return '$bookName $from–$to';
  }

  static String _formatPart(int chapter, int? verse) {
    return verse == null ? '$chapter' : '$chapter:$verse';
  }
}

/// Task.description marker that contains Bible refs.
///
/// Format:
///   [[BIBLE_REFS:{json}]]
///
/// json is an object:
///   {"v":1,"refs":[...BibleRef.toJson...]}
const kBibleRefsMarkerPrefix = '[[BIBLE_REFS:';
const kBibleRefsMarkerSuffix = ']]';

String upsertBibleRefsInDescription(String description, List<BibleRef> refs) {
  // Remove existing marker.
  final stripped = stripBibleRefsFromDescription(description).trimRight();

  if (refs.isEmpty) return stripped;

  final payload = jsonEncode({
    'v': 1,
    'refs': refs.map((e) => e.toJson()).toList(growable: false),
  });

  return '$stripped\n\n$kBibleRefsMarkerPrefix$payload$kBibleRefsMarkerSuffix';
}

String stripBibleRefsFromDescription(String description) {
  final start = description.indexOf(kBibleRefsMarkerPrefix);
  if (start < 0) return description;

  final end = description.indexOf(
    kBibleRefsMarkerSuffix,
    start + kBibleRefsMarkerPrefix.length,
  );
  if (end < 0) return description;

  return description.replaceRange(start, end + kBibleRefsMarkerSuffix.length, '');
}

List<BibleRef> parseBibleRefsFromDescription(String description) {
  final start = description.indexOf(kBibleRefsMarkerPrefix);
  if (start < 0) return const [];

  final end = description.indexOf(
    kBibleRefsMarkerSuffix,
    start + kBibleRefsMarkerPrefix.length,
  );
  if (end < 0) return const [];

  final jsonPart = description.substring(
    start + kBibleRefsMarkerPrefix.length,
    end,
  );

  try {
    final decoded = jsonDecode(jsonPart);
    if (decoded is! Map) return const [];
    final refsAny = decoded['refs'];
    if (refsAny is! List) return const [];

    return refsAny
        .whereType<Map>()
        .map((e) => BibleRef.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.bookId.trim().isNotEmpty)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
