import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';
import 'models/user_model.dart';

/// Holds the current authenticated user in memory.
///
/// IMPORTANT: this is the single source of truth for authentication.
/// - AsyncLoading: we are resolving session (/auth/me)
/// - AsyncData(null): unauthenticated
/// - AsyncData(UserModel): authenticated
/// - AsyncError: session resolution failed (network/server)
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Resolve required gates exactly once per dependency change.
    // Using `.future` here is correct: it blocks until resolved.
    final token = await ref.watch(authTokenProvider.future);
    final baseUrl = await ref.watch(baseUrlProvider.future);

    // Hard gate: never call /auth/me without both baseUrl and token.
    if (baseUrl.isEmpty) return null;
    if (token == null || token.isEmpty) return null;

    // IMPORTANT: do NOT watch providers again here.
    // Watching in build would make this provider rebuild and re-call /auth/me
    // on unrelated refresh cycles.

    final repo = ref.read(authRepositoryProvider);
    final me = await repo.me();
    return me;
  }

  Future<UserModel> loadMe() async {
    final repo = ref.read(authRepositoryProvider);
    final me = await repo.me();
    state = AsyncData(me);
    return me;
  }

  void clear() {
    state = const AsyncData(null);
  }

  /// Internal: set state directly from external code (e.g. register response).
  /// Keeps the rest of the app reactive without exposing Notifier.state outside.
  void setUser(UserModel? user) {
    state = AsyncData(user);
  }
}

/// Stores auth token and exposes it as AsyncValue.
///
/// This removes the race condition where token is briefly null while being
/// loaded from SecureStorage.
///
/// States:
/// - AsyncLoading: token is not resolved yet
/// - AsyncData(null): no token (logged out)
/// - AsyncData(token): logged in
final authTokenProvider = AsyncNotifierProvider<AuthTokenNotifier, String?>(
  AuthTokenNotifier.new,
);

class AuthTokenNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final store = ref.read(secureStoreProvider);
    final saved = await store.getToken();
    return (saved != null && saved.isNotEmpty) ? saved : null;
  }

  Future<void> setToken(String token) async {
    final store = ref.read(secureStoreProvider);
    await store.setToken(token);
    state = AsyncData(token);
  }

  Future<void> clearToken() async {
    final store = ref.read(secureStoreProvider);
    await store.clearToken();
    state = const AsyncData(null);

    // Also clear user cache.
    ref.read(currentUserProvider.notifier).clear();
  }
}

/// NOTE: sessionBootstrapProvider has been removed.
///
/// Rationale: this provider was a second entry-point that could trigger
/// `/auth/me` outside of [CurrentUserNotifier.build].
///
/// Invariant: `/auth/me` must be called ONLY from currentUserProvider.build()
/// after `await ref.watch(authTokenProvider.future)`.

/// A ChangeNotifier proxy to refresh GoRouter when auth/baseUrl changes.
final routerRefreshNotifierProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Emits only the routing-relevant session fields.
///
/// IMPORTANT: profile edits (firstName/lastName/city) must NOT trigger router
/// refresh nor router recreation.
final routerSessionKeyProvider = Provider<String?>((ref) {
  final token = ref.watch(authTokenProvider).valueOrNull;
  final user = ref.watch(currentUserProvider).valueOrNull;
  final churchId = user?.churchId;
  final role = user?.role.trim().toUpperCase();
  // token can be null/empty.
  return '${token ?? ''}|${churchId ?? ''}|${role ?? ''}';
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _tokenSub = _ref.listen<AsyncValue<String?>>(
      authTokenProvider,
      (_, __) => notifyListeners(),
    );
    _baseUrlSub = _ref.listen<AsyncValue<String>>(
      baseUrlProvider,
      (_, __) => notifyListeners(),
    );
    _authStateSub = _ref.listen<String?>(
      routerSessionKeyProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<String?>> _tokenSub;
  late final ProviderSubscription<AsyncValue<String>> _baseUrlSub;
  late final ProviderSubscription<String?> _authStateSub;

  @override
  void dispose() {
    _tokenSub.close();
    _baseUrlSub.close();
    _authStateSub.close();
    super.dispose();
  }
}
