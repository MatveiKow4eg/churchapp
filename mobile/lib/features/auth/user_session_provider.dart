import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/user_model.dart';
import 'session_providers.dart';

/// Source of truth for the current user session across the whole app.
///
/// Rules:
/// - Prefer user from [AuthState] (coming from /auth/me).
/// - Fallback to [currentUserProvider] (legacy cache/in-memory saved user).
/// - Always guarantees a non-null, normalized role string when user exists.
final userSessionProvider = Provider<UserModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

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
    avatarConfig: user.avatarConfig,
    avatarUpdatedAt: user.avatarUpdatedAt,
  );
});

/// Derived role from server-confirmed user.
///
/// IMPORTANT: do not default to USER when role is unknown while loading.
/// Router/guards should rely on [currentUserProvider] and only treat
/// a user as authenticated when AsyncValue has non-null data.
final userRoleProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final role = userAsync.valueOrNull?.role;
  return role?.trim().toUpperCase();
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'ADMIN' || role == 'SUPERADMIN' || role == 'SUPERADMIN';
});
