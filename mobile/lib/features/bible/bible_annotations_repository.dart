import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import 'bible_annotations_storage.dart' show BibleHighlightColor;

class BibleAnnotationDto {
  BibleAnnotationDto({
    required this.translationId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    this.highlight,
    this.isFavorite,
    this.note,
  });

  final String translationId;
  final String bookId;
  final int chapter;
  final int verse;

  /// Stored as lowercase string: yellow|green|blue|pink|purple
  final String? highlight;
  final bool? isFavorite;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'translationId': translationId,
      'bookId': bookId,
      'chapter': chapter,
      'verse': verse,
      if (highlight != null) 'highlight': highlight,
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (note != null) 'note': note,
    };
  }

  factory BibleAnnotationDto.fromJson(Map<String, dynamic> json) {
    return BibleAnnotationDto(
      translationId: (json['translationId'] ?? '').toString(),
      bookId: (json['bookId'] ?? '').toString(),
      chapter: (json['chapter'] is int)
          ? json['chapter'] as int
          : int.tryParse((json['chapter'] ?? '').toString()) ?? 0,
      verse: (json['verse'] is int)
          ? json['verse'] as int
          : int.tryParse((json['verse'] ?? '').toString()) ?? 0,
      highlight: (json['highlight'] is String) ? json['highlight'] as String : null,
      isFavorite: (json['isFavorite'] is bool) ? json['isFavorite'] as bool : null,
      note: (json['note'] is String) ? json['note'] as String : null,
    );
  }

  static String? normalizeHighlight(BibleHighlightColor? c) => c?.name;
}

class BibleAnnotationsRepository {
  BibleAnnotationsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<BibleAnnotationDto>> listAll() async {
    try {
      final res = await _apiClient.dio.get(
        '/bible/annotations/all',
      );

      final raw = res.data;
      final itemsAny = (raw is Map<String, dynamic>)
          ? (raw['items'] as List? ?? const [])
          : (raw as List? ?? const []);

      return itemsAny
          .whereType<Map>()
          .map((e) => BibleAnnotationDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiClient.mapDioError(e);
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<List<BibleAnnotationDto>> list({
    required String translationId,
    required String bookId,
    required int chapter,
  }) async {
    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>(
        '/bible/annotations',
        queryParameters: {
          'translationId': translationId,
          'bookId': bookId,
          'chapter': chapter,
        },
      );

      final data = res.data;
      final itemsAny = (data ?? const <String, dynamic>{})['items'];
      if (itemsAny is! List) return const [];

      return itemsAny
          .whereType<Map>()
          .map((e) => BibleAnnotationDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiClient.mapDioError(e);
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<List<BibleAnnotationDto>> upsert(List<BibleAnnotationDto> items) async {
    try {
      final res = await _apiClient.dio.put<Map<String, dynamic>>(
        '/bible/annotations',
        data: {
          'items': items.map((e) => e.toJson()).toList(growable: false),
        },
      );

      final data = res.data;
      final itemsAny = (data ?? const <String, dynamic>{})['items'];
      if (itemsAny is! List) return const [];

      return itemsAny
          .whereType<Map>()
          .map((e) => BibleAnnotationDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiClient.mapDioError(e);
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }
}
