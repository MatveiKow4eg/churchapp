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

/// LEGACY (DISABLED): kept only to satisfy old imports.
///
/// IMPORTANT INVARIANT: `/auth/me` must be called ONLY from
/// [CurrentUserNotifier.build] in session_providers.dart.
///
/// This provider is intentionally "dumb" and never calls network.
final authStateProvider = Provider<AuthState>((ref) {
  return const Unauthenticated();
});
