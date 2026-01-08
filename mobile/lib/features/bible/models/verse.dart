class Verse {
  const Verse({
    required this.number,
    required this.text,
    required this.rawJson,
  });

  final int number;
  final String text;

  /// Keeps the original payload for forward compatibility.
  final Map<String, dynamic> rawJson;

  /// Best-effort parsing.
  /// Returns null when structure/format is not recognized.
  /// Never throws.
  static Verse? tryParse(dynamic v) {
    try {
      if (v == null) return null;

      int? intOrNull(dynamic x) {
        if (x is int) return x;
        if (x is String) return int.tryParse(x);
        return null;
      }

      String? strOrNull(dynamic x) {
        if (x is String) {
          final s = x.trim();
          return s.isEmpty ? null : s;
        }
        if (x == null) return null;
        final s = x.toString().trim();
        return s.isEmpty ? null : s;
      }

      if (v is Map) {
        final map = Map<String, dynamic>.from(v);

        final number =
            intOrNull(map['verseNumber']) ??
            intOrNull(map['verse_number']) ??
            intOrNull(map['verse']) ??
            intOrNull(map['number']) ??
            intOrNull(map['v']) ??
            (map['id'] is int ? map['id'] as int : null);

        if (number == null) return null;

        String? text;

        // 1) plain text fields
        text = strOrNull(map['text']) ?? strOrNull(map['t']);

        // 2) content as string
        text ??= (map['content'] is String) ? strOrNull(map['content']) : null;

        // 3) content as list (rich runs)
        if (text == null && map['content'] is List) {
          final parts = <String>[];
          for (final item in (map['content'] as List)) {
            final s = switch (item) {
              String _ => strOrNull(item),
              Map _ => strOrNull((item as Map)['text']) ??
                  strOrNull(item['content']) ??
                  strOrNull(item['value']),
              _ => strOrNull(item?.toString()),
            };
            if (s != null) parts.add(s);
          }

          final joined = parts.join(' ').trim();
          if (joined.isNotEmpty) text = joined;
        }

        if (text == null || text.trim().isEmpty) return null;

        return Verse(number: number, text: text, rawJson: map);
      }

      if (v is String) {
        // Try format like "1 In the beginning..."
        final s = v.trim();
        final match = RegExp(r'^(\\d+)\\s+(.+)$').firstMatch(s);
        if (match == null) return null;

        final number = int.tryParse(match.group(1) ?? '');
        final text = (match.group(2) ?? '').trim();
        if (number == null || text.isEmpty) return null;

        return Verse(number: number, text: text, rawJson: const {});
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Backward-compatible constructor used by older code.
  factory Verse.fromJson(Map<String, dynamic> json) {
    return tryParse(json) ?? Verse(number: 0, text: '', rawJson: json);
  }
}
