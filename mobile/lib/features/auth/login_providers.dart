import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';

import 'auth_repository.dart';
import 'models/auth_result.dart';
import 'auth_state.dart';
import 'session_providers.dart';

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, void>(LoginController.new);

class LoginController extends AsyncNotifier<void> {
  late final AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<AuthResult> login(LoginRequest req) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.login(
        email: req.email,
        password: req.password,
      );

      // Update auth state (router redirect relies on it).
      await ref.read(authTokenProvider.notifier).setToken(result.token);

      // Refresh global AuthState (token + /auth/me -> churchId)
      ref.invalidate(authStateProvider);

      // /auth/login returns token only; load profile via /auth/me.
      try {
        await ref.read(currentUserProvider.notifier).loadMe();
      } on AppError catch (e) {
        final code = e.code.toUpperCase();
        if (code == 'UNAUTHORIZED' || code == 'USER_NOT_FOUND' || code == '404') {
          await ref.read(authTokenProvider.notifier).clearToken();
          throw const AppError(
            code: 'SESSION_INVALID',
            message: 'Сессия недействительна. Войдите снова.',
          );
        }
        rethrow;
      }

      state = const AsyncData(null);
      return result;
    } on AppError catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    } catch (_) {
      const fallback = AppError(
        code: 'network',
        message: 'Ошибка сети. Проверь подключение и адрес сервера.',
      );
      state = AsyncError(fallback, StackTrace.current);
      throw fallback;
    }
  }
}
