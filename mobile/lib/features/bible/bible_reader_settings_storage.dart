import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BibleReaderSettings {
  const BibleReaderSettings({
    this.fontSize = 18,
    this.lineHeight = 1.45,
    this.horizontalPadding = 16,
    this.showVerseNumbers = true,
  });

  final double fontSize;
  final double lineHeight;
  final double horizontalPadding;
  final bool showVerseNumbers;

  BibleReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? horizontalPadding,
    bool? showVerseNumbers,
  }) {
    return BibleReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'horizontalPadding': horizontalPadding,
      'showVerseNumbers': showVerseNumbers,
    };
  }

  factory BibleReaderSettings.fromJson(Map<String, dynamic> json) {
    return BibleReaderSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? defaults.lineHeight,
      horizontalPadding:
          (json['horizontalPadding'] as num?)?.toDouble() ?? defaults.horizontalPadding,
      showVerseNumbers: json['showVerseNumbers'] as bool? ?? defaults.showVerseNumbers,
    );
  }

  static const defaults = BibleReaderSettings(
    fontSize: 18,
    lineHeight: 1.45,
    horizontalPadding: 16,
    showVerseNumbers: true,
  );
}

class BibleReaderSettingsStorage {
  final FlutterSecureStorage storage;
  BibleReaderSettingsStorage(this.storage);

  static const _key = 'bible.reader.settings';

  Future<void> save(BibleReaderSettings s) =>
      storage.write(key: _key, value: jsonEncode(s.toJson()));

  Future<BibleReaderSettings> load() async {
    final v = await storage.read(key: _key);
    if (v == null || v.isEmpty) return BibleReaderSettings.defaults;

    try {
      final decoded = jsonDecode(v);
      if (decoded is Map<String, dynamic>) {
        return BibleReaderSettings.fromJson(decoded);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}

    return BibleReaderSettings.defaults;
  }

  Future<void> clear() => storage.delete(key: _key);
}
