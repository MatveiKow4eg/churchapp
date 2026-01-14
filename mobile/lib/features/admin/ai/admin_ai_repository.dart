import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_error.dart';

class AdminAiRepository {
  AdminAiRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<String>> suggestTaskTitles({required String text}) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/ai/task-title-suggest',
        data: {
          'text': text.trim(),
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final items = data['items'];
      if (items is! List) {
        throw const AppError(
          code: 'invalid_response',
          message: 'Invalid response format',
        );
      }

      return items
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // AI endpoints return { error: { code, message } }
      final err = data is Map ? data['error'] : null;
      final errCode = err is Map ? (err['code']?.toString() ?? '') : '';
      if (errCode.isNotEmpty) {
        throw AppError(code: errCode, message: errCode);
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }
      if (status == 403) {
        throw const AppError(code: 'FORBIDDEN', message: 'FORBIDDEN');
      }
      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<String> rewriteTaskDescription({required String text}) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/ai/task-description-rewrite',
        data: {
          'text': text.trim(),
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final t = data['text'];
      if (t is! String || t.trim().isEmpty) {
        throw const AppError(
          code: 'invalid_response',
          message: 'Invalid response format',
        );
      }

      return t.trim();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // AI endpoints return { error: { code, message } }
      final err = data is Map ? data['error'] : null;
      final errCode = err is Map ? (err['code']?.toString() ?? '') : '';
      if (errCode.isNotEmpty) {
        throw AppError(code: errCode, message: errCode);
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }
      if (status == 403) {
        throw const AppError(code: 'FORBIDDEN', message: 'FORBIDDEN');
      }
      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  AppError _mapToRequiredError(Object e) {
    final mapped = ApiClient.mapDioError(e);

    final msg = mapped.message;
    final isBackendMessage = msg != 'Connection timeout' &&
        msg != 'Request send timeout' &&
        msg != 'Response timeout' &&
        msg != 'Bad SSL certificate' &&
        msg != 'Request cancelled' &&
        msg != 'Network connection error' &&
        !msg.startsWith('Server error') &&
        msg != 'Unknown network error';

    if (isBackendMessage) {
      return AppError(code: mapped.code, message: msg);
    }

    return AppError(
      code: mapped.code,
      message: 'Ошибка сети. Проверь адрес сервера.',
    );
  }
}
