import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import 'admin_ai_repository.dart';

final adminAiRepositoryProvider = Provider<AdminAiRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AdminAiRepository(apiClient: apiClient);
});
