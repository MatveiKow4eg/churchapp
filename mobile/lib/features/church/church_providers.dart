import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'church_repository.dart';
import 'models/church_model.dart';

final churchRepositoryProvider = Provider<ChurchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChurchRepository(apiClient: apiClient);
});

final churchSearchProvider =
    AutoDisposeAsyncNotifierProvider<ChurchSearchNotifier, List<ChurchModel>>(
  ChurchSearchNotifier.new,
);

class ChurchSearchNotifier extends AutoDisposeAsyncNotifier<List<ChurchModel>> {
  @override
  Future<List<ChurchModel>> build() async {
    // Idle state until user triggers search.
    return const [];
  }

  Future<void> search(String searchText) async {
    final q = searchText.trim();
    if (q.isEmpty || q.length < 2) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(churchRepositoryProvider);
      return repo.searchChurches(search: q);
    });
  }
}
