/// DiceBear URL helpers.
///
/// Example:
/// `https://example.com/avatars/dicebear/adventurer.png?size=256&seed=alice&backgroundColor=ffcc00`
///
/// Notes:
/// This project proxies DiceBear through the backend under `/avatars/...`.
Uri buildAdventurerPngUrl(String baseUrl, Map<String, dynamic> options) {
  final query = <String, String>{
    // Required by DiceBear PNG endpoint.
    'size': '256',
  };

  for (final entry in options.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value == null) continue;

    // Empty string / empty list are omitted.
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) continue;
      query[key] = v;
      continue;
    }

    if (value is bool) {
      query[key] = value ? 'true' : 'false';
      continue;
    }

    if (value is int) {
      query[key] = value.toString();
      continue;
    }

    if (value is List<String>) {
      final items = value.where((e) => e.trim().isNotEmpty).toList();
      if (items.isEmpty) continue;
      query[key] = items.join(',');
      continue;
    }

    // Fallback: serialize anything else (e.g. enums already converted by caller).
    final asString = value.toString().trim();
    if (asString.isEmpty) continue;
    query[key] = asString;
  }

  final normalizedBaseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  return Uri.parse('$normalizedBaseUrl/avatars/dicebear/adventurer.png')
      .replace(queryParameters: query);
}
