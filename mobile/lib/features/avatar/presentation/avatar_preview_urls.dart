/// URL builders for avatar previews.
///
/// This is used for small thumbnail previews (e.g. option grids) where we want
/// to render the current avatar with a single option overridden.

/// Builds a DiceBear Adventurer PNG thumbnail URL via the backend proxy.
///
/// [baseOptions] should be the current options map (typically
/// `AvatarOptions.toQuery()`), [overrideOptions] is merged on top.
///
/// Always sets `size`.
///
/// Also removes option params that should be considered "off" so that previews
/// accurately reflect toggles:
/// - if `glassesProbability == 0` -> remove `glasses`
/// - if `featuresProbability == 0` -> remove `features`
/// - if `earringsProbability == 0` -> remove `earrings`
Uri buildAdventurerThumbUrl({
  required String baseUrl,
  required Map<String, dynamic> baseOptions,
  required Map<String, dynamic> overrideOptions,
  int size = 96,
}) {
  // Merge base + overrides. Use string values in query params.
  final merged = <String, dynamic>{
    ...baseOptions,
    ...overrideOptions,
  };

  // Always override size.
  merged['size'] = size.toString();

  void removeIfOff({required String probabilityKey, required String paramKey}) {
    final prob = merged[probabilityKey];

    // Accept int/double/num or numeric strings.
    num? parsed;
    if (prob is num) {
      parsed = prob;
    } else if (prob is String) {
      parsed = num.tryParse(prob);
    }

    if (parsed != null && parsed == 0) {
      merged.remove(paramKey);
    }
  }

  removeIfOff(probabilityKey: 'glassesProbability', paramKey: 'glasses');
  removeIfOff(probabilityKey: 'featuresProbability', paramKey: 'features');
  removeIfOff(probabilityKey: 'earringsProbability', paramKey: 'earrings');

  // Filter out nulls and stringify values for query.
  final query = <String, String>{};
  for (final entry in merged.entries) {
    final value = entry.value;
    if (value == null) continue;
    query[entry.key] = value.toString();
  }

  final normalizedBaseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  return Uri.parse('$normalizedBaseUrl/avatars/dicebear/adventurer.png')
      .replace(queryParameters: query);
}
