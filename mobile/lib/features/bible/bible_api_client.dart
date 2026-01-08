import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Simple API client for Bible endpoints served via our backend.
///
/// Note: This is a lightweight foundation client (no Riverpod here).
class BibleApiClient {
  BibleApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ''));

  final Dio _dio;

  Future<List<dynamic>> getTranslations() async {
    try {
      // DEBUG (temporary): ensure we use backend baseUrl and no Authorization.
      // ignore: avoid_print
      print(
        '[bible][dio] baseUrl=${_dio.options.baseUrl} hasAuth=${_dio.options.headers['Authorization'] != null} headers=${_dio.options.headers}',
      );

      final res = await _dio.get('/bible/translations');
      final data = res.data;

      // debug (temporary)
      // ignore: avoid_print
      debugPrint('[bible] getTranslations dataType=${data.runtimeType}');

      if (data is List) return data;

      if (data is Map) {
        final candidates = [
          data['translations'],
          data['items'],
          data['data'],
        ];

        for (final c in candidates) {
          if (c is List) return c;
        }

        return data.values.toList();
      }

      throw Exception('Unexpected translations response type: ${data.runtimeType}');
    } on DioException catch (e) {
      throw Exception('Bible API getTranslations failed: ${e.message}');
    } catch (e) {
      throw Exception('Bible API getTranslations parse failed: $e');
    }
  }

  Future<List<dynamic>> getBooks(String translationId) async {
    try {
      // DEBUG (temporary): ensure we use backend baseUrl and no Authorization.
      // ignore: avoid_print
      print(
        '[bible][dio] baseUrl=${_dio.options.baseUrl} hasAuth=${_dio.options.headers['Authorization'] != null} headers=${_dio.options.headers}',
      );

      final res = await _dio.get('/bible/$translationId/books');
      final data = res.data;

      // debug (temporary)
      // ignore: avoid_print
      debugPrint('[bible] getBooks dataType=${data.runtimeType}');

      if (data is List) return data;

      if (data is Map) {
        // common wrappers
        final candidates = [
          data['books'],
          data['items'],
          data['data'],
        ];

        for (final c in candidates) {
          if (c is List) return c;
        }

        // map like {"GEN": {...}, "EXO": {...}}
        return data.values.toList();
      }

      throw Exception('Unexpected books response type: ${data.runtimeType}');
    } on DioException catch (e) {
      throw Exception('Bible API getBooks($translationId) failed: ${e.message}');
    } catch (e) {
      throw Exception('Bible API getBooks($translationId) parse failed: $e');
    }
  }

  Future<Map<String, dynamic>> getChapter(
    String translationId,
    String bookId,
    int chapter,
  ) async {
    try {
      // DEBUG (temporary): ensure we use backend baseUrl and no Authorization.
      // ignore: avoid_print
      print('[bible][dio] baseUrl=${_dio.options.baseUrl} hasAuth=${_dio.options.headers['Authorization'] != null} headers=${_dio.options.headers}');

      final res = await _dio.get<Map<String, dynamic>>(
        '/bible/$translationId/$bookId/$chapter',
      );
      final data = res.data;
      if (data == null) {
        throw Exception(
          'Bible API: empty chapter response for $translationId/$bookId/$chapter',
        );
      }
      return data;
    } on DioException catch (e) {
      throw Exception(
        _friendlyDioError('getChapter($translationId, $bookId, $chapter)', e),
      );
    }
  }

  Future<Map<String, dynamic>> searchInBook({
    required String translationId,
    required String bookId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final queryParameters = {
        'bookId': bookId,
        'q': query,
        'limit': limit,
      };

      debugPrint(
        '[bible] search url=/bible/$translationId/search qp=$queryParameters',
      );

      final res = await _dio.get(
        '/bible/$translationId/search',
        queryParameters: queryParameters,
      );

      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      throw Exception('Unexpected search response type: ${data.runtimeType}');
    } on DioException catch (e) {
      throw Exception('Bible search failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> searchPreview({
    required String translationId,
    required String query,
    int limit = 4,
    int timeBudgetMs = 2500,
  }) async {
    try {
      final res = await _dio.get(
        '/bible/$translationId/search-preview',
        queryParameters: {
          'q': query,
          'limit': limit,
          'timeBudgetMs': timeBudgetMs,
        },
      );

      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      throw Exception('Unexpected search-preview response type: ${data.runtimeType}');
    } on DioException catch (e) {
      throw Exception('Bible preview search failed: ${e.message}');
    } catch (e) {
      throw Exception('Bible preview search parse failed: $e');
    }
  }

  Future<Map<String, dynamic>> searchAllRaw({
    required String translationId,
    required String q,
    int limit = 200,
    int offset = 0,
    int timeBudgetMs = 15000,
  }) async {
    try {
      final res = await _dio.get(
        '/bible/$translationId/search-all',
        queryParameters: {
          'q': q,
          'limit': limit,
          'offset': offset,
          'timeBudgetMs': timeBudgetMs,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      throw Exception('Unexpected search-all response type: ${data.runtimeType}');
    } on DioException catch (e) {
      throw Exception('Bible search-all failed: ${e.message}');
    }
  }

  String _friendlyDioError(String operation, DioException e) {
    final status = e.response?.statusCode;
    final statusPart = status == null ? '' : ' (HTTP $status)';

    // Keep it readable; response payload often is not stable.
    final msg = e.message;
    if (msg != null && msg.trim().isNotEmpty) {
      return 'Bible API $operation failed$statusPart: $msg';
    }

    return 'Bible API $operation failed$statusPart';
  }
}
