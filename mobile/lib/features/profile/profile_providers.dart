import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/xp_status.dart';
import 'settings_controller.dart';

/// Loads current user's XP/level progress from GET /me/xp.
final myXpStatusProvider = FutureProvider<XpStatus>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.fetchMyXp();
});
