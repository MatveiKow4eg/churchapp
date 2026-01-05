import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../shop/shop_providers.dart';
import 'inventory_repository.dart';
import 'models/inventory_item_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryRepository(apiClient: apiClient);
});

class InventoryController extends AsyncNotifier<List<InventoryItemModel>> {
  @override
  Future<List<InventoryItemModel>> build() async {
    final repo = ref.watch(inventoryRepositoryProvider);
    final items = await repo.fetchMyInventory();

    // Integration: update ownedItemIds in shop.
    ref.read(ownedItemIdsProvider.notifier).state =
        items.map((e) => e.itemId).where((id) => id.isNotEmpty).toSet();

    return items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(inventoryRepositoryProvider);
      final items = await repo.fetchMyInventory();

      ref.read(ownedItemIdsProvider.notifier).state =
          items.map((e) => e.itemId).where((id) => id.isNotEmpty).toSet();

      return items;
    });
  }
}

final inventoryItemsProvider =
    AsyncNotifierProvider<InventoryController, List<InventoryItemModel>>(
  InventoryController.new,
);
