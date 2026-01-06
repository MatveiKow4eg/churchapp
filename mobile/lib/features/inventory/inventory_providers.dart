import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'inventory_repository.dart';
import 'models/inventory_item_model.dart';
import 'models/server_inventory_item.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryRepository(apiClient: apiClient);
});

/// Legacy controller (pre-itemKey). Kept so older code compiles.
class InventoryController extends AsyncNotifier<List<InventoryItemModel>> {
  @override
  Future<List<InventoryItemModel>> build() async {
    final repo = ref.watch(inventoryRepositoryProvider);
    return repo.fetchMyInventory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(inventoryRepositoryProvider);
      return repo.fetchMyInventory();
    });
  }
}

final inventoryItemsProvider =
    AsyncNotifierProvider<InventoryController, List<InventoryItemModel>>(
  InventoryController.new,
);

/// Step 14.5.3: server inventory list.
final serverInventoryProvider = FutureProvider<List<ServerInventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchMyServerInventory();
});
