/// Utilities for normalizing DiceBear schema option ordering.
///
/// DiceBear schema enums are not guaranteed to be ordered, but the UI expects
/// a human-friendly stable ordering.

/// Sort schema variants in a stable, human-friendly way.
///
/// Rules:
/// - `variant\d+` sorts by numeric suffix ascending.
/// - `(short|long)\d+` sorts by group (`short` first, then `long`) and numeric
///   suffix ascending.
/// - Otherwise: alphabetical.
///
/// Stability: when two items compare as equal under the above rules, their
/// relative order from [items] is preserved.
List<String> sortVariants(List<String> items) {
  final indexed = items.indexed.toList(growable: false);

  final variantRe = RegExp(r'^variant(\d+)$');
  final hairRe = RegExp(r'^(short|long)(\d+)$');

  int classify(String v) {
    // Lower is earlier.
    if (hairRe.hasMatch(v)) return 0;
    if (variantRe.hasMatch(v)) return 1;
    return 2;
  }

  int groupRank(String v) {
    final m = hairRe.firstMatch(v);
    if (m == null) return 999;
    final group = m.group(1);
    if (group == 'short') return 0;
    if (group == 'long') return 1;
    return 999;
  }

  int numericSuffixOrNeg1(RegExp re, String v) {
    final m = re.firstMatch(v);
    if (m == null) return -1;
    return int.parse(m.group(m.groupCount)!);
  }

  int compareValues(String a, String b) {
    final ca = classify(a);
    final cb = classify(b);
    if (ca != cb) return ca.compareTo(cb);

    if (ca == 0) {
      // short/long variants
      final ga = groupRank(a);
      final gb = groupRank(b);
      if (ga != gb) return ga.compareTo(gb);

      final na = numericSuffixOrNeg1(hairRe, a);
      final nb = numericSuffixOrNeg1(hairRe, b);
      if (na != nb) return na.compareTo(nb);

      // Same bucket, same number -> treat as equal (stability via index)
      return 0;
    }

    if (ca == 1) {
      // variantXX
      final na = numericSuffixOrNeg1(variantRe, a);
      final nb = numericSuffixOrNeg1(variantRe, b);
      if (na != nb) return na.compareTo(nb);
      return 0;
    }

    // fallback alphabetical
    final c = a.compareTo(b);
    if (c != 0) return c;
    return 0;
  }

  indexed.sort((a, b) {
    final c = compareValues(a.$2, b.$2);
    if (c != 0) return c;
    // stable tie-breaker
    return a.$1.compareTo(b.$1);
  });

  return [for (final e in indexed) e.$2];
}
