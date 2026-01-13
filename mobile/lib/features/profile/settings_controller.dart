import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';
import '../../core/api/api_client.dart';
import 'data/xp_status.dart';
import '../auth/session_providers.dart';
import '../auth/user_session_provider.dart';
import '../auth/models/user_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsRepository(apiClient: apiClient);
});

final settingsControllerProvider = AutoDisposeAsyncNotifierProvider<
    SettingsController, void>(SettingsController.new);

class SettingsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // idle
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    String? city,
  }) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        city: city,
      );

      // NOTE: Do not call loadMe() here.
      // Refreshing currentUserProvider triggers GoRouter redirect recalculation and
      // can kick the user out of Settings flow (e.g. to /tasks) depending on guards.
      // We optimistically update local user session state below.
      final prev = ref.read(currentUserProvider).valueOrNull;
      if (prev != null) {
        ref.read(currentUserProvider.notifier).setUser(
              UserModel(
                id: prev.id,
                firstName: firstName,
                lastName: lastName,
                age: prev.age,
                city: city ?? prev.city,
                email: prev.email,
                role: prev.role,
                status: prev.status,
                churchId: prev.churchId,
                avatarConfig: prev.avatarConfig,
                avatarUpdatedAt: prev.avatarUpdatedAt,
              ),
            );
      }
      ref.invalidate(userSessionProvider);

      state = const AsyncData(null);
    } on AppError catch (e, st) {
      if (e.code == 'UNAUTHORIZED') {
        await ref.read(authTokenProvider.notifier).clearToken();
        ref.invalidate(currentUserProvider);
      }
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = const AsyncData(null);
    } on AppError catch (e, st) {
      if (e.code == 'UNAUTHORIZED') {
        await ref.read(authTokenProvider.notifier).clearToken();
        ref.invalidate(currentUserProvider);
      }
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> changeEmail({
    required String newEmail,
  }) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.changeEmail(newEmail: newEmail);

      // refresh user so email is updated in UI
      await ref.read(currentUserProvider.notifier).loadMe();
      ref.invalidate(userSessionProvider);

      state = const AsyncData(null);
    } on AppError catch (e, st) {
      if (e.code == 'UNAUTHORIZED') {
        await ref.read(authTokenProvider.notifier).clearToken();
        ref.invalidate(currentUserProvider);
      }
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> leaveChurch() async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.leaveChurch();

      await ref.read(currentUserProvider.notifier).loadMe();
      ref.invalidate(userSessionProvider);

      state = const AsyncData(null);
    } on AppError catch (e, st) {
      if (e.code == 'UNAUTHORIZED') {
        await ref.read(authTokenProvider.notifier).clearToken();
        ref.invalidate(currentUserProvider);
      }
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// Simple repository colocated to keep feature self-contained.
// If the project later introduces a dedicated /me repository, move it there.
class SettingsRepository {
  SettingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<XpStatus> fetchMyXp() async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>('/me/xp');
      return XpStatus.fromJson(resp.data ?? const <String, dynamic>{});
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? city,
  }) async {
    try {
      final data = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
      };
      if (city != null) {
        data['city'] = city;
      }

      await _apiClient.dio.put(
        '/me/profile',
        data: data,
      );
    } catch (e) {
      final mapped = ApiClient.mapDioError(e);
      // Friendly fallback if backend doesn't have this endpoint.
      if (mapped.code == 'NOT_FOUND') {
        throw const AppError(
          code: 'NOT_FOUND',
          message:
              'Сервер не поддерживает /me/profile. Перезапусти backend и убедись, что приложение подключено к правильному адресу.',
        );
      }
      throw mapped;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/me/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      final mapped = ApiClient.mapDioError(e);
      if (mapped.code == 'NOT_FOUND') {
        throw const AppError(
          code: 'NOT_FOUND',
          message: 'Сервер не поддерживает смену пароля',
        );
      }
      throw mapped;
    }
  }

  Future<void> changeEmail({
    required String newEmail,
  }) async {
    try {
      await _apiClient.dio.post(
        '/me/change-email',
        data: {
          'newEmail': newEmail,
        },
      );
    } catch (e) {
      final mapped = ApiClient.mapDioError(e);
      if (mapped.code == 'NOT_FOUND') {
        throw const AppError(
          code: 'NOT_FOUND',
          message: 'Сервер не поддерживает смену email',
        );
      }
      throw mapped;
    }
  }

  Future<void> leaveChurch() async {
    try {
      await _apiClient.dio.post('/me/leave-church');
    } catch (e) {
      final mapped = ApiClient.mapDioError(e);
      if (mapped.code == 'NOT_FOUND') {
        throw const AppError(
          code: 'NOT_FOUND',
          message: 'В разработке: выход из церкви недоступен на сервере',
        );
      }
      throw mapped;
    }
  }
}
