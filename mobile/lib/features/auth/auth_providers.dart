import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';

import 'auth_repository.dart';
import 'models/auth_result.dart';
import 'session_providers.dart';

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, void>(RegisterController.new);

class RegisterController extends AsyncNotifier<void> {
  late final AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<AuthResult> register(RegisterRequest req) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.register(
        email: req.email,
        password: req.password,
        firstName: req.firstName,
        lastName: req.lastName,
        age: req.age,
        city: req.city,
      );

      // Update auth state (router redirect relies on it).
      await ref.read(authTokenProvider.notifier).setToken(result.token);

      // Refresh current user session (will re-run /auth/me if token exists)
      ref.invalidate(currentUserProvider);

      // Register usually returns user, but we keep a single source of truth.
      if (result.user != null) {
        ref.read(currentUserProvider.notifier).setUser(result.user);
      } else {
        await ref.read(currentUserProvider.notifier).loadMe();
      }

      state = const AsyncData(null);
      return result;
    } on AppError catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    } catch (e) {
      const fallback = AppError(
        code: 'network',
        message: 'Ошибка сети. Проверь подключение и адрес сервера.',
      );
      state = AsyncError(fallback, StackTrace.current);
      throw fallback;
    }
  }
}
