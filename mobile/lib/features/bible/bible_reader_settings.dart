import 'dart:convert';

/// Immutable settings for Bible reader UI.
class BibleReaderSettings {
  const BibleReaderSettings({
    this.fontSize = 19,
    this.lineHeight = 1.45,
    this.showVerseNumbers = true,
    this.horizontalPadding = 16,
  });

  final double fontSize;
  final double lineHeight;
  final bool showVerseNumbers;
  final double horizontalPadding;

  factory BibleReaderSettings.defaults() => const BibleReaderSettings();

  BibleReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    bool? showVerseNumbers,
    double? horizontalPadding,
  }) {
    return BibleReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'showVerseNumbers': showVerseNumbers,
      'horizontalPadding': horizontalPadding,
    };
  }

  factory BibleReaderSettings.fromJson(Map<String, dynamic> json) {
    return BibleReaderSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 19,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.45,
      showVerseNumbers: json['showVerseNumbers'] as bool? ?? true,
      horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 16,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static BibleReaderSettings fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return BibleReaderSettings.fromJson(decoded);
    }
    // Be defensive against unexpected payloads.
    return BibleReaderSettings.defaults();
  }
}
