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
