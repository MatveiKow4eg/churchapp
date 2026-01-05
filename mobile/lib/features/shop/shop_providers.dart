import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'models/shop_item_model.dart';
import 'shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShopRepository(apiClient: apiClient);
});

final shopItemsFilterProvider = StateProvider<ShopItemsFilter>((ref) {
  return const ShopItemsFilter(activeOnly: true, type: null);
});

class ShopItemsFilter {
  const ShopItemsFilter({required this.activeOnly, required this.type});

  final bool activeOnly;
  final String? type;
}

class ShopItemsController extends AsyncNotifier<List<ShopItemModel>> {
  @override
  Future<List<ShopItemModel>> build() async {
    final filter = ref.watch(shopItemsFilterProvider);
    final repo = ref.watch(shopRepositoryProvider);

    return repo.fetchItems(activeOnly: filter.activeOnly, type: filter.type);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(shopItemsFilterProvider);
      final repo = ref.read(shopRepositoryProvider);
      return repo.fetchItems(activeOnly: filter.activeOnly, type: filter.type);
    });
  }
}

final shopItemsProvider =
    AsyncNotifierProvider<ShopItemsController, List<ShopItemModel>>(
  ShopItemsController.new,
);

/// Cached balance. We don't fetch it separately yet (step 12.3 will improve this).
final balanceProvider = StateProvider<int?>((ref) => null);

/// MVP: local list of owned items. Step 12.3 (GET /me/inventory) will replace
/// this with real inventory state on entering the shop.
final ownedItemIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Item-specific purchase loading state.
final purchaseLoadingItemIdProvider = StateProvider<String?>((ref) => null);
