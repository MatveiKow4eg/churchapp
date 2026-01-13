import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import 'church_stats_repository.dart';
import 'models/church_stats_model.dart';

final churchStatsRepositoryProvider = Provider<ChurchStatsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChurchStatsRepository(apiClient: apiClient);
});

String _currentMonthYYYYMM() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  return '$y-$m';
}

final selectedChurchStatsMonthProvider = StateProvider<String>((ref) {
  return _currentMonthYYYYMM();
});

class ChurchStatsController extends AsyncNotifier<ChurchStatsModel> {
  @override
  Future<ChurchStatsModel> build() async {
    final month = ref.watch(selectedChurchStatsMonthProvider);
    final repo = ref.watch(churchStatsRepositoryProvider);
    return repo.fetchChurchStats(month);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final month = ref.read(selectedChurchStatsMonthProvider);
      final repo = ref.read(churchStatsRepositoryProvider);
      return repo.fetchChurchStats(month);
    });
  }
}

final churchStatsProvider =
    AsyncNotifierProvider<ChurchStatsController, ChurchStatsModel>(
  ChurchStatsController.new,
);
