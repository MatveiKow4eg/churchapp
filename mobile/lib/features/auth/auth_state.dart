import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';
import 'session_providers.dart';
import '../auth/auth_repository.dart';
import 'models/user_model.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthenticatedNoChurch extends AuthState {
  const AuthenticatedNoChurch({required this.token, required this.user});

  final String token;
  final UserModel user;
}

class AuthenticatedReady extends AuthState {
  const AuthenticatedReady({required this.token, required this.user});

  final String token;
  final UserModel user;
}

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Prefer in-memory token provider to avoid race with SecureStore read.
    final token = ref.watch(authTokenProvider) ?? '';

    // Token might still be loading on first frame.
    if (token.isEmpty) {
      // If authTokenProvider not loaded yet, keep loading.
      // We detect that by waiting one microtask and checking again.
      await Future<void>.delayed(Duration.zero);
      final t2 = ref.read(authTokenProvider) ?? '';
      if (t2.isEmpty) {
        return const Unauthenticated();
      }
    }

    final effectiveToken = token.isNotEmpty ? token : (ref.read(authTokenProvider) ?? '');

    if (effectiveToken.isEmpty) {
      return const Unauthenticated();
    }

    // Token exists -> fetch /auth/me for churchId.
    final AuthRepository repo = ref.read(authRepositoryProvider);

    try {
      final UserModel me = await repo.me();

      // Keep the user available app-wide as a fallback cache.
      ref.read(currentUserProvider.notifier).setUser(me);

      if (me.churchId == null || me.churchId!.isEmpty) {
        return AuthenticatedNoChurch(token: effectiveToken, user: me);
      }
      return AuthenticatedReady(token: effectiveToken, user: me);
    } on AppError catch (e) {
      // If /auth/me returned 401 -> clear token and treat as unauthenticated.
      if (e.code.toUpperCase() == 'UNAUTHORIZED' || e.code == '401') {
        await ref.read(authTokenProvider.notifier).clearToken();
        return const Unauthenticated();
      }

      // For other errors: keep user in no-church state (do not block app with splash forever).
      // Keep user signed-in, but user data is unavailable.
      // Role must still be present (source of truth requires it).
      return AuthenticatedNoChurch(
        token: effectiveToken,
        user: const UserModel(
          id: '',
          firstName: '',
          lastName: '',
          age: 0,
          city: '',
          role: 'USER',
          status: '',
          churchId: null,
        ),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
