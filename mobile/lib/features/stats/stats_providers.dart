import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'models/user_stats_model.dart';
import 'stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatsRepository(apiClient: apiClient);
});

String _currentMonthYYYYMM() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  return '$y-$m';
}

final selectedStatsMonthProvider = StateProvider<String>((ref) {
  return _currentMonthYYYYMM();
});

class MyStatsController extends AsyncNotifier<UserStatsModel> {
  @override
  Future<UserStatsModel> build() async {
    final month = ref.watch(selectedStatsMonthProvider);
    final repo = ref.watch(statsRepositoryProvider);
    return repo.fetchMyStats(month);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final month = ref.read(selectedStatsMonthProvider);
      final repo = ref.read(statsRepositoryProvider);
      return repo.fetchMyStats(month);
    });
  }
}

final myStatsProvider = AsyncNotifierProvider<MyStatsController, UserStatsModel>(
  MyStatsController.new,
);
