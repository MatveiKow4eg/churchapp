import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';

import 'models/auth_result.dart';
import 'models/user_model.dart';

class AuthRepository {
  const AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AuthResult> register({
    String? email,
    String? username,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String city,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '/auth/register',
        data: {
          if (email != null) 'email': email,
          if (username != null) 'username': username,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'age': age,
          'city': city,
        },
      );

      final data = res.data;
      if (data is! Map) {
        throw const AppError(code: 'bad_response', message: 'Unexpected response');
      }

      return AuthResult.fromJson(data.cast<String, dynamic>());
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final data = res.data;
      if (data is! Map) {
        throw const AppError(code: 'bad_response', message: 'Unexpected response');
      }

      return AuthResult.fromJson(data.cast<String, dynamic>());
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final res = await _apiClient.dio.get('/auth/me');

      final data = res.data;
      if (data is! Map) {
        throw const AppError(code: 'bad_response', message: 'Unexpected response');
      }

      // /auth/me returns an envelope: `{ user, church?, balance? }`.
      // We need the whole envelope so UserModel can extract optional church fields.
      return UserModel.fromJson(data.cast<String, dynamic>());
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<UserModel> saveAvatarConfig(Map<String, dynamic> avatarConfig) async {
    try {
      final res = await _apiClient.dio.put(
        '/me/avatar',
        data: {
          'avatarConfig': avatarConfig,
        },
      );

      final data = res.data;
      if (data is! Map) {
        throw const AppError(code: 'bad_response', message: 'Unexpected response');
      }

      final rawUser = data['user'];
      if (rawUser is Map) {
        return UserModel.fromJson(rawUser.cast<String, dynamic>());
      }

      throw const AppError(code: 'bad_response', message: 'Missing user in response');
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }
}
