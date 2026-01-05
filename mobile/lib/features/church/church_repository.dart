import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import 'models/church_model.dart';
import 'models/join_church_result.dart';

class ChurchRepository {
  ChurchRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ChurchModel>> searchChurches({
    required String search,
    int limit = 20,
  }) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/churches',
        queryParameters: {
          'search': search,
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
          .map((e) => ChurchModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<JoinChurchResult> joinChurch({required String churchId}) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/churches/$churchId/join',
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(
            code: 'invalid_response', message: 'Empty response');
      }

      return JoinChurchResult.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // Explicit UX messages
      if (status == 401) {
        throw const AppError(
          code: 'UNAUTHORIZED',
          message: 'Сессия истекла, зарегистрируйся заново',
        );
      }

      if (status == 409) {
        throw const AppError(
          code: 'CONFLICT',
          message: 'Ты уже состоишь в церкви. Перезайди в приложение.',
        );
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
