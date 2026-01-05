import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';
import 'auth_state.dart';
import 'models/user_model.dart';

/// Holds the current authenticated user in memory.
final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  Future<UserModel> loadMe() async {
    final repo = ref.read(authRepositoryProvider);
    final me = await repo.me();
    state = me;
    return me;
  }

  void clear() {
    state = null;
  }

  /// Internal: set state directly from external code (e.g. register response).
  /// Keeps the rest of the app reactive without exposing Notifier.state outside.
  void setUser(UserModel? user) {
    state = user;
  }
}

/// Stores auth token in memory and syncs it with SecureStore.
/// This is used by router redirects to decide whether user is authenticated.
final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(
  AuthTokenNotifier.new,
);

class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() {
    state = null;
    Future.microtask(_loadFromStorage);
    return state;
  }

  Future<void> _loadFromStorage() async {
    final store = ref.read(secureStoreProvider);
    final saved = await store.getToken();
    if (saved != state) {
      state = saved;
    }
  }

  Future<void> setToken(String token) async {
    final store = ref.read(secureStoreProvider);
    await store.setToken(token);
    state = token;
  }

  Future<void> clearToken() async {
    final store = ref.read(secureStoreProvider);
    await store.clearToken();
    state = null;

    // Optional: also clear user cache.
    ref.read(currentUserProvider.notifier).clear();
  }
}

final isAuthenticatedProvider = Provider<bool>((ref) {
  final token = ref.watch(authTokenProvider);
  return token != null && token.isNotEmpty;
});

/// Validates stored token by calling /auth/me once after token is loaded.
/// If token is invalid / user removed -> clears token so router redirects to /login.
final sessionBootstrapProvider = Provider<SessionBootstrapper>((ref) {
  final bootstrapper = SessionBootstrapper(ref);
  ref.onDispose(bootstrapper.dispose);
  return bootstrapper;
});

class SessionBootstrapper {
  SessionBootstrapper(this._ref) {
    _tokenSub = _ref.listen<String?>(authTokenProvider, (prev, next) {
      // Run only when token becomes available/changes.
      if (next != null && next.isNotEmpty && next != prev) {
        unawaited(_validateSession());
      }
    });
  }

  final Ref _ref;
  late final ProviderSubscription<String?> _tokenSub;

  Future<void> _validateSession() async {
    try {
      await _ref.read(currentUserProvider.notifier).loadMe();
    } on AppError catch (e) {
      // If token is invalid or user is gone -> clear token.
      final code = e.code.toUpperCase();
      if (code == 'UNAUTHORIZED' || code == 'USER_NOT_FOUND' || code == '404') {
        await _ref.read(authTokenProvider.notifier).clearToken();
      }
    } catch (_) {
      // Ignore non-AppError failures to avoid forcing logout on transient errors.
    }
  }

  void dispose() {
    _tokenSub.close();
  }
}

/// A ChangeNotifier proxy to refresh GoRouter when auth/baseUrl changes.
final routerRefreshNotifierProvider = Provider<_RouterRefreshNotifier>((ref) {
  // Ensure bootstrapper is alive while router is alive.
  ref.watch(sessionBootstrapProvider);

  // Ensure auth state provider stays alive so GoRouter can read it in redirect.
  ref.watch(authStateProvider);

  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _tokenSub =
        _ref.listen<String?>(authTokenProvider, (_, __) => notifyListeners());
    _baseUrlSub =
        _ref.listen<String>(baseUrlProvider, (_, __) => notifyListeners());
    _authStateSub = _ref.listen<AsyncValue>(
        authStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<String?> _tokenSub;
  late final ProviderSubscription<String> _baseUrlSub;
  late final ProviderSubscription<AsyncValue> _authStateSub;

  @override
  void dispose() {
    _tokenSub.close();
    _baseUrlSub.close();
    _authStateSub.close();
    super.dispose();
  }
}
