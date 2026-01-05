import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import 'models/submission_model.dart';
import 'models/pending_submission_item.dart';
import 'models/submission_action_result.dart';

class SubmissionsRepository {
  SubmissionsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PendingSubmissionItem>> fetchPending({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/submissions/pending',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final items = data['items'];
      if (items is! List) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return items
          .whereType<Map>()
          .map((e) => PendingSubmissionItem.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (statusCode == 403) {
        throw const AppError(code: 'FORBIDDEN', message: 'FORBIDDEN');
      }

      if (statusCode == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<SubmissionActionResult> approve(
    String submissionId, {
    String? commentAdmin,
  }) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/submissions/$submissionId/approve',
        data: {
          if (commentAdmin != null && commentAdmin.trim().isNotEmpty)
            'commentAdmin': commentAdmin.trim(),
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      return SubmissionActionResult.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (status == 403) {
        throw const AppError(code: 'FORBIDDEN', message: 'FORBIDDEN');
      }

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map) {
          final code = err['code']?.toString() ?? '';
          if (code == 'NO_CHURCH') {
            throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
          }
          if (code == 'CONFLICT') {
            throw const AppError(code: 'CONFLICT', message: 'CONFLICT');
          }
        }
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<SubmissionActionResult> reject(
    String submissionId, {
    String? commentAdmin,
  }) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/submissions/$submissionId/reject',
        data: {
          if (commentAdmin != null && commentAdmin.trim().isNotEmpty)
            'commentAdmin': commentAdmin.trim(),
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      return SubmissionActionResult.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (status == 403) {
        throw const AppError(code: 'FORBIDDEN', message: 'FORBIDDEN');
      }

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map) {
          final code = err['code']?.toString() ?? '';
          if (code == 'NO_CHURCH') {
            throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
          }
          if (code == 'CONFLICT') {
            throw const AppError(code: 'CONFLICT', message: 'CONFLICT');
          }
        }
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<SubmissionModel> createSubmission({
    required String taskId,
    String? commentUser,
  }) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/submissions',
        data: {
          'taskId': taskId,
          if (commentUser != null && commentUser.trim().isNotEmpty)
            'commentUser': commentUser.trim(),
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(
            code: 'invalid_response', message: 'Empty response');
      }

      final raw = data['submission'];
      if (raw is! Map) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return SubmissionModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map) {
          final code = err['code']?.toString() ?? '';
          if (code == 'NO_CHURCH') {
            throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
          }
          if (code == 'CONFLICT') {
            throw const AppError(
              code: 'CONFLICT',
              message: 'Ты уже отправлял это задание на проверку',
            );
          }
        }
      }

      if (status == 403 || status == 404) {
        throw const AppError(code: 'FORBIDDEN', message: 'Задание недоступно');
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<List<SubmissionModel>> fetchMySubmissions({
    String? status,
    int limit = 30,
  }) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/submissions/mine',
        queryParameters: {
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          'limit': limit,
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(
            code: 'invalid_response', message: 'Empty response');
      }

      final items = data['items'];
      if (items is! List) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return items
          .whereType<Map>()
          .map((e) => SubmissionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (statusCode == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  AppError _mapToRequiredError(Object e) {
    final mapped = ApiClient.mapDioError(e);

    // Prefer backend message when exists; otherwise show network error.
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
        code: mapped.code, message: 'Ошибка сети. Проверь адрес сервера.');
  }
}
