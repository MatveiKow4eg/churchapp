class BibleSearchHit {
  const BibleSearchHit({
    required this.chapter,
    required this.verse,
    required this.text,
    this.ref,
  });

  final int chapter;
  final int verse;
  final String text;
  final String? ref;

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v is String) return v;
    if (v == null) return fallback;
    return v.toString();
  }

  factory BibleSearchHit.fromJson(Map<String, dynamic> json) {
    final chapter = _asInt(json['chapter']);
    final verse = _asInt(json['verse']);
    final text = _asString(json['text']);
    final refRaw = json['ref'];
    final refStr = refRaw == null ? null : _asString(refRaw).trim();

    return BibleSearchHit(
      chapter: chapter,
      verse: verse,
      text: text,
      ref: (refStr == null || refStr.isEmpty) ? null : refStr,
    );
  }
}

class BibleSearchResponse {
  const BibleSearchResponse({
    required this.translationId,
    required this.bookId,
    required this.query,
    required this.total,
    required this.results,
  });

  final String translationId;
  final String bookId;
  final String query;
  final int total;
  final List<BibleSearchHit> results;

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v is String) return v;
    if (v == null) return fallback;
    return v.toString();
  }

  factory BibleSearchResponse.fromJson(Map<String, dynamic> json) {
    final translationId = _asString(json['translationId']);
    final bookId = _asString(json['bookId']);
    final query = _asString(json['query']);
    final total = _asInt(json['total']);

    final resultsAny = json['results'];
    final hits = <BibleSearchHit>[];
    if (resultsAny is List) {
      for (final e in resultsAny) {
        if (e is Map) {
          hits.add(BibleSearchHit.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return BibleSearchResponse(
      translationId: translationId,
      bookId: bookId,
      query: query,
      total: total > 0 ? total : hits.length,
      results: hits,
    );
  }
}
