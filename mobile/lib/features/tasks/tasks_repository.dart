import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import 'models/task_model.dart';

class TasksRepository {
  TasksRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String category,
    required int pointsReward,
  }) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/tasks',
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'category': category.trim(),
          'pointsReward': pointsReward,
        },
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final rawTask = data['task'];
      if (rawTask is! Map) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return TaskModel.fromJson(Map<String, dynamic>.from(rawTask));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
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

  Future<TaskModel> updateTask(
    String taskId, {
    required Map<String, dynamic> patch,
  }) async {
    try {
      final resp = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/tasks/$taskId',
        data: patch,
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final rawTask = data['task'];
      if (rawTask is! Map) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return TaskModel.fromJson(Map<String, dynamic>.from(rawTask));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
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

  Future<TaskModel> deactivateTask(String taskId) async {
    try {
      final resp = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/tasks/$taskId/deactivate',
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final rawTask = data['task'];
      if (rawTask is! Map) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return TaskModel.fromJson(Map<String, dynamic>.from(rawTask));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
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

  Future<List<TaskModel>> fetchTasks({
    bool activeOnly = true,
    String? category,
  }) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/tasks',
        queryParameters: {
          'activeOnly': activeOnly,
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
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
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // Special cases
      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<TaskModel> fetchTaskById(String id) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/tasks/$id',
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(
            code: 'invalid_response', message: 'Empty response');
      }

      final rawTask = data['task'];
      if (rawTask is! Map) {
        throw const AppError(
            code: 'invalid_response', message: 'Invalid response format');
      }

      return TaskModel.fromJson(Map<String, dynamic>.from(rawTask));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      if (status == 403 || status == 404) {
        throw const AppError(
            code: 'TASK_UNAVAILABLE', message: 'Задание недоступно');
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  AppError _mapToRequiredError(Object e) {
    // Requirement: if backend returns { error: { message } } show that,
    // otherwise show: "Ошибка сети. Проверь адрес сервера."
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
        code: mapped.code, message: 'Ошибка сети. Проверь адрес сервера.');
  }
}
