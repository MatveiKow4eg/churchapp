import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../storage/secure_store.dart';

import '../../features/auth/auth_repository.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

/// Synchronous baseUrl state that is loaded once from storage on first use.
/// Empty string means "not configured".
final baseUrlProvider = NotifierProvider<BaseUrlNotifier, String>(BaseUrlNotifier.new);

class BaseUrlNotifier extends Notifier<String> {
  @override
  String build() {
    // Default while loading. We load from storage asynchronously and update state.
    state = '';

    // Fire-and-forget init load.
    Future.microtask(_loadFromStorage);

    return state;
  }

  Future<void> _loadFromStorage() async {
    final store = ref.read(secureStoreProvider);
    final saved = (await store.getBaseUrl()) ?? '';

    // Avoid unnecessary rebuilds.
    if (saved != state) {
      state = saved;
    }
  }

  Future<void> setBaseUrl(String baseUrl) async {
    final store = ref.read(secureStoreProvider);
    await store.setBaseUrl(baseUrl);
    state = baseUrl;
  }

  Future<void> clearBaseUrl() async {
    final store = ref.read(secureStoreProvider);
    await store.clearBaseUrl();
    state = '';
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return AppConfig(baseUrl: baseUrl);
});

/// ApiClient is created based on the latest baseUrl and current token getter.
final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(secureStoreProvider);
  final config = ref.watch(appConfigProvider);

  return ApiClient(
    baseUrl: config.baseUrl,
    getToken: store.getToken,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});
