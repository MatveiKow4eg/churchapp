import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../storage/secure_store.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/session_providers.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

// AppConfig is fixed to production settings for App Store build.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.production();
});

/// ApiClient is created based on the fixed baseUrl and current token getter.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);

  // IMPORTANT:
  // Don't capture `tokenAsync.valueOrNull` in a closure.
  // That value can be null during provider rebuilds, causing requests (like /me/ping)
  // to be sent without Authorization even when the user is logged in.
  // Instead, read the latest token on every request.
  return ApiClient(
    baseUrl: config.baseUrl,
    getToken: () async => ref.read(authTokenProvider).valueOrNull,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});
