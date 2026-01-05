import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../storage/secure_store.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/session_providers.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

/// Base URL is loaded from storage asynchronously.
/// - loading: we don't know yet if server is configured
/// - data(''): not configured -> must go to /server
/// - data(url): configured
final baseUrlProvider = AsyncNotifierProvider<BaseUrlNotifier, String>(
  BaseUrlNotifier.new,
);

class BaseUrlNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final store = ref.read(secureStoreProvider);
    return (await store.getBaseUrl()) ?? '';
  }

  Future<void> setBaseUrl(String baseUrl) async {
    final store = ref.read(secureStoreProvider);
    await store.setBaseUrl(baseUrl);
    state = AsyncData(baseUrl);
  }

  Future<void> clearBaseUrl() async {
    final store = ref.read(secureStoreProvider);
    await store.clearBaseUrl();
    state = const AsyncData('');
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  final baseUrlAsync = ref.watch(baseUrlProvider);
  final baseUrl = baseUrlAsync.valueOrNull ?? '';
  return AppConfig(baseUrl: baseUrl);
});

/// ApiClient is created based on the latest baseUrl and current token getter.
final apiClientProvider = Provider<ApiClient>((ref) {
  // IMPORTANT: ApiClient must use the same token source as router/auth state.
  // We intentionally do NOT read token directly from SecureStore here, because
  // SecureStore is async and can lag behind after login.
  final config = ref.watch(appConfigProvider);

  // Watch token so ApiClient always uses the latest value.
  final tokenAsync = ref.watch(authTokenProvider);

  return ApiClient(
    baseUrl: config.baseUrl,
    getToken: () async => tokenAsync.valueOrNull,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});
