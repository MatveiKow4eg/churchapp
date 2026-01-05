import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'models/user_model.dart';
import 'session_providers.dart';

/// Source of truth for the current user session across the whole app.
///
/// Rules:
/// - Prefer user from [AuthState] (coming from /auth/me).
/// - Fallback to [currentUserProvider] (legacy cache/in-memory saved user).
/// - Always guarantees a non-null, normalized role string when user exists.
final userSessionProvider = Provider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  UserModel? user;

  final auth = authAsync.valueOrNull;
  if (auth is AuthenticatedNoChurch) {
    user = auth.user;
  } else if (auth is AuthenticatedReady) {
    user = auth.user;
  } else {
    user = ref.watch(currentUserProvider);
  }

  if (user == null) return null;

  // Guarantee role exists and is normalized.
  final role = (user.role).trim().toUpperCase();
  return UserModel(
    id: user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    age: user.age,
    city: user.city,
    role: role.isEmpty ? 'USER' : role,
    status: user.status,
    churchId: user.churchId,
  );
});

final userRoleProvider = Provider<String>((ref) {
  return ref.watch(userSessionProvider)?.role ?? 'USER';
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'ADMIN' || role == 'SUPERADMIN';
});
