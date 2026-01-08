import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'bible_api_client.dart';
import 'bible_repository.dart';

final bibleApiClientProvider = Provider<BibleApiClient>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.baseUrl == kBaseUrlLoadingMarker) {
    throw StateError('BibleApiClient requested while baseUrl is still loading');
  }
  if (config.baseUrl.isEmpty) {
    throw StateError('BibleApiClient requested while baseUrl is empty (not configured)');
  }

  // Separate Dio instance WITHOUT auth interceptor.
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  return BibleApiClient(dio: dio);
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(apiClient: ref.watch(bibleApiClientProvider));
});
