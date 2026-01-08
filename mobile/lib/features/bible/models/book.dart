class Book {
  const Book({
    required this.id,
    required this.name,
    this.chaptersCount,
    required this.rawJson,
  });

  final String id;
  final String name;

  /// Optional because API may vary.
  final int? chaptersCount;

  /// Keeps the original payload for forward compatibility.
  final Map<String, dynamic> rawJson;

  factory Book.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v is String ? v : (v?.toString() ?? '');

    int? intOrNull(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    // Some APIs use different naming conventions; keep a few common candidates.
    // 1) Numeric fields.
    final chaptersFromNumber = intOrNull(json['chapters_count']) ??
        intOrNull(json['chaptersCount']) ??
        intOrNull(json['numberOfChapters']) ??
        intOrNull(json['chapters']) ??
        intOrNull(json['number_of_chapters']);

    // 2) Arrays of chapters/links.
    int? chaptersFromList(dynamic v) {
      if (v is List) return v.length;
      return null;
    }

    final chaptersFromArray = chaptersFromList(json['chapter_links']) ??
        chaptersFromList(json['chapters_links']) ??
        chaptersFromList(json['chaptersLinks']) ??
        chaptersFromList(json['chapters_list']) ??
        chaptersFromList(json['chaptersList']) ??
        chaptersFromList(json['chapters']);

    // Prefer explicit numeric value over array length.
    final chapters = chaptersFromNumber ?? chaptersFromArray;

    return Book(
      id: str(json['id']),
      name: str(json['name']),
      chaptersCount: chapters,
      rawJson: json,
    );
  }
}
