/// Avatar options for DiceBear (Adventurer).
///
/// Field names and [toQuery] keys are aligned with DiceBear query parameters.
class AvatarOptions {
  final String seed;

  final String? backgroundColor;
  final String? skinColor;

  final String? hair;
  final String? hairColor;

  final String? eyes;
  final String? eyebrows;
  final String? mouth;

  final String? glasses;
  final int glassesProbability;

  final String? features;
  final int featuresProbability;

  final String? earrings;
  final int earringsProbability;

  const AvatarOptions({
    required this.seed,
    this.backgroundColor,
    this.skinColor,
    this.hair,
    this.hairColor,
    this.eyes,
    this.eyebrows,
    this.mouth,
    this.glasses,
    this.glassesProbability = 0,
    this.features,
    this.featuresProbability = 0,
    this.earrings,
    this.earringsProbability = 0,
  });

  /// Reasonable defaults to produce a consistent, pleasant avatar.
  factory AvatarOptions.defaults({required String seed}) {
    return AvatarOptions(
      seed: seed,
      backgroundColor: 'b6e3f4',
      skinColor: 'f2d3b1',
      hair: 'short12',
      hairColor: '0e0e0e',
      eyes: 'variant01',
      eyebrows: 'variant03',
      mouth: 'variant01',
      glassesProbability: 0,
      featuresProbability: 0,
      earringsProbability: 0,
    );
  }

  /// Converts this model to DiceBear query parameters.
  ///
  /// Keys are exactly as DiceBear expects.
  Map<String, dynamic> toQuery() {
    return {
      'seed': seed,
      'backgroundColor': backgroundColor,
      'skinColor': skinColor,
      'hair': hair,
      'hairColor': hairColor,
      'eyes': eyes,
      'eyebrows': eyebrows,
      'mouth': mouth,
      'glasses': glasses,
      'glassesProbability': glassesProbability,
      'features': features,
      'featuresProbability': featuresProbability,
      'earrings': earrings,
      'earringsProbability': earringsProbability,
    };
  }

  static const Object _unset = Object();

  AvatarOptions copyWith({
    String? seed,
    String? backgroundColor,
    String? skinColor,
    String? hair,
    String? hairColor,
    String? eyes,
    String? eyebrows,
    String? mouth,
    Object? glasses = _unset,
    int? glassesProbability,
    Object? features = _unset,
    int? featuresProbability,
    Object? earrings = _unset,
    int? earringsProbability,
  }) {
    return AvatarOptions(
      seed: seed ?? this.seed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      skinColor: skinColor ?? this.skinColor,
      hair: hair ?? this.hair,
      hairColor: hairColor ?? this.hairColor,
      eyes: eyes ?? this.eyes,
      eyebrows: eyebrows ?? this.eyebrows,
      mouth: mouth ?? this.mouth,
      glasses: glasses == _unset ? this.glasses : glasses as String?,
      glassesProbability: glassesProbability ?? this.glassesProbability,
      features: features == _unset ? this.features : features as String?,
      featuresProbability: featuresProbability ?? this.featuresProbability,
      earrings: earrings == _unset ? this.earrings : earrings as String?,
      earringsProbability: earringsProbability ?? this.earringsProbability,
    );
  }
}
