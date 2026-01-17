import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// User annotations for Bible verses: highlights, favorites, and notes.
///
/// Storage is intentionally simple (secure storage JSON) to keep it offline-first.
class BibleAnnotationsStorage {
  BibleAnnotationsStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kKey = 'bible.annotations.v1';

  Future<BibleAnnotations> load() async {
    final raw = await _storage.read(key: _kKey);
    if (raw == null || raw.trim().isEmpty) return const BibleAnnotations();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return BibleAnnotations.fromJson(decoded);
      }
    } catch (_) {
      // Be resilient to schema changes / corrupted storage.
    }

    return const BibleAnnotations();
  }

  Future<void> save(BibleAnnotations data) async {
    await _storage.write(key: _kKey, value: jsonEncode(data.toJson()));
  }
}

@immutable
class BibleVerseRef {
  const BibleVerseRef({
    required this.translationId,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  final String translationId;
  final String bookId;
  final int chapter;
  final int verse;

  String get key => '$translationId:$bookId:$chapter:$verse';

  factory BibleVerseRef.fromKey(String key) {
    final parts = key.split(':');
    if (parts.length != 4) {
      throw FormatException('Invalid BibleVerseRef key: $key');
    }
    return BibleVerseRef(
      translationId: parts[0],
      bookId: parts[1],
      chapter: int.tryParse(parts[2]) ?? 0,
      verse: int.tryParse(parts[3]) ?? 0,
    );
  }
}

/// Highlight color palette we support in UI.
/// Stored as enum name.
enum BibleHighlightColor {
  yellow,
  green,
  blue,
  pink,
  purple,
}

extension BibleHighlightColorX on BibleHighlightColor {
  Color get color {
    switch (this) {
      case BibleHighlightColor.yellow:
        return const Color(0xFFFFEB3B);
      case BibleHighlightColor.green:
        return const Color(0xFF66BB6A);
      case BibleHighlightColor.blue:
        return const Color(0xFF42A5F5);
      case BibleHighlightColor.pink:
        return const Color(0xFFEC407A);
      case BibleHighlightColor.purple:
        return const Color(0xFFAB47BC);
    }
  }

  String get labelRu {
    switch (this) {
      case BibleHighlightColor.yellow:
        return 'Жёлтый';
      case BibleHighlightColor.green:
        return 'Зелёный';
      case BibleHighlightColor.blue:
        return 'Синий';
      case BibleHighlightColor.pink:
        return 'Розовый';
      case BibleHighlightColor.purple:
        return 'Фиолетовый';
    }
  }
}

@immutable
class BibleVerseAnnotation {
  const BibleVerseAnnotation({
    this.highlight,
    this.isFavorite = false,
    this.note,
    this.updatedAt,
  });

  final BibleHighlightColor? highlight;
  final bool isFavorite;
  final String? note;
  final DateTime? updatedAt;

  BibleVerseAnnotation copyWith({
    BibleHighlightColor? highlight,
    bool clearHighlight = false,
    bool? isFavorite,
    String? note,
    DateTime? updatedAt,
  }) {
    return BibleVerseAnnotation(
      highlight: clearHighlight ? null : (highlight ?? this.highlight),
      isFavorite: isFavorite ?? this.isFavorite,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty => highlight == null && !isFavorite && (note == null || note!.trim().isEmpty);

  Map<String, dynamic> toJson() {
    return {
      'highlight': highlight?.name,
      'favorite': isFavorite,
      'note': note,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory BibleVerseAnnotation.fromJson(Map<String, dynamic> json) {
    final h = json['highlight'];
    BibleHighlightColor? color;
    if (h is String && h.isNotEmpty) {
      color = BibleHighlightColor.values.where((e) => e.name == h).cast<BibleHighlightColor?>().firstWhere(
            (e) => e != null,
            orElse: () => null,
          );
    }

    return BibleVerseAnnotation(
      highlight: color,
      isFavorite: json['favorite'] == true,
      note: (json['note'] as String?),
      updatedAt: (json['updatedAt'] is String)
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

@immutable
class BibleAnnotations {
  const BibleAnnotations({
    this.byVerseKey = const <String, BibleVerseAnnotation>{},
  });

  /// key = [BibleVerseRef.key]
  final Map<String, BibleVerseAnnotation> byVerseKey;

  BibleVerseAnnotation annotationFor(BibleVerseRef ref) {
    return byVerseKey[ref.key] ?? const BibleVerseAnnotation();
  }

  BibleAnnotations copyWithVerse(BibleVerseRef ref, BibleVerseAnnotation ann) {
    final next = Map<String, BibleVerseAnnotation>.from(byVerseKey);
    if (ann.isEmpty) {
      next.remove(ref.key);
    } else {
      next[ref.key] = ann;
    }
    return BibleAnnotations(byVerseKey: next);
  }

  Map<String, dynamic> toJson() {
    return {
      'v': 1,
      'verses': byVerseKey.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory BibleAnnotations.fromJson(Map<String, dynamic> json) {
    final versesAny = json['verses'];
    final map = <String, BibleVerseAnnotation>{};
    if (versesAny is Map) {
      for (final entry in versesAny.entries) {
        final k = entry.key;
        final v = entry.value;
        if (k is String && v is Map) {
          map[k] = BibleVerseAnnotation.fromJson(Map<String, dynamic>.from(v));
        }
      }
    }
    return BibleAnnotations(byVerseKey: map);
  }
}
