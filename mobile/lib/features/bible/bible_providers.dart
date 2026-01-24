import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'bible_api_client.dart';
import 'bible_repository.dart';

final bibleApiClientProvider = Provider<BibleApiClient>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.baseUrl.isEmpty) {
    throw StateError('BibleApiClient requested while baseUrl is empty (not configured)');
  }

  // IMPORTANT:
  // Bible endpoints include both public (text/search) and protected endpoints
  // (annotations). Use the shared ApiClient's Dio so Authorization header is
  // attached automatically.
  final apiClient = ref.watch(apiClientProvider);
  return BibleApiClient(dio: apiClient.dio);
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(apiClient: ref.watch(bibleApiClientProvider));
});
