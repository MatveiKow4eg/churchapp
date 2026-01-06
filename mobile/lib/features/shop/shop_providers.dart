import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_error.dart';
import '../../core/providers/providers.dart';
import '../catalog/catalog_providers.dart';
import '../inventory/inventory_providers.dart';
import 'models/server_shop_item.dart';
import 'models/shop_item_model.dart';
import 'models/shop_view_item.dart';
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

/// Cached balance. We don't fetch it separately yet.
final balanceProvider = StateProvider<int?>((ref) => null);

/// Legacy (itemId-based). Kept so older code compiles.
final ownedItemIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Legacy (itemId-based). Kept so older code compiles.
final purchaseLoadingItemIdProvider = StateProvider<String?>((ref) => null);

/// Step 14.5.3: server shop items.
final serverShopItemsProvider = FutureProvider<List<ServerShopItem>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.fetchServerShopItems();
});

/// Step 14.5.3: set of owned catalog keys.
final ownedKeysProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final items = await repo.fetchMyServerInventory();
  return items.map((e) => e.itemKey).where((e) => e.isNotEmpty).toSet();
});

/// Item-specific purchase loading state (itemKey).
final purchaseLoadingKeyProvider = StateProvider<String?>((ref) => null);

/// Merged list used by ShopScreen.
final shopViewItemsProvider = FutureProvider<List<ShopViewItem>>((ref) async {
  final catalogItems = await ref.watch(catalogProvider.future);
  final serverItems = await ref.watch(serverShopItemsProvider.future);
  final ownedKeys = await ref.watch(ownedKeysProvider.future);

  final serverByKey = <String, ServerShopItem>{
    for (final s in serverItems) s.itemKey: s,
  };

  final view = <ShopViewItem>[];
  for (final c in catalogItems) {
    final server = serverByKey[c.key];
    if (server == null) continue; // hide items not present in server shop

    view.add(
      ShopViewItem(
        key: c.key,
        name: c.displayName(locale: 'ru'),
        iconPath: c.iconPath,
        layerPath: c.layerPath,
        slot: c.slot,
        rarity: c.rarity,
        pricePoints: server.pricePoints,
        isActive: server.isActive,
        owned: ownedKeys.contains(c.key),
      ),
    );
  }

  view.sort((a, b) {
    // owned вниз
    if (a.owned != b.owned) return a.owned ? 1 : -1;
    // затем price
    return a.pricePoints.compareTo(b.pricePoints);
  });

  return view;
});

class PurchaseController {
  PurchaseController(this.ref);
  final WidgetRef ref;

  String? get loadingKey => ref.read(purchaseLoadingKeyProvider);

  Future<void> purchase(BuildContext context, String itemKey) async {
    final rootScaffoldMessenger = ScaffoldMessenger.of(context);
    final rootRouter = GoRouter.of(context);

    ref.read(purchaseLoadingKeyProvider.notifier).state = itemKey;

    try {
      final repo = ref.read(shopRepositoryProvider);
      final result = await repo.purchaseByKey(itemKey);

      ref.read(balanceProvider.notifier).state = result.balance;

      // refresh owned keys (source of truth)
      ref.invalidate(ownedKeysProvider);

      rootScaffoldMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Куплено!')));
    } on AppError catch (e) {
      if (e.code == 'NO_CHURCH') {
        rootRouter.go('/church');
        return;
      }
      if (e.code == 'UNAUTHORIZED') {
        rootRouter.go('/register');
        return;
      }

      final msgLower = e.message.toLowerCase();
      final msg = msgLower.contains('insufficient')
          ? 'Недостаточно очков'
          : msgLower.contains('already owned')
              ? 'Уже куплено'
              : (e.message.isNotEmpty ? e.message : 'Ошибка сети');

      rootScaffoldMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      rootScaffoldMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Ошибка сети')));
    } finally {
      final current = ref.read(purchaseLoadingKeyProvider);
      if (current == itemKey) {
        ref.read(purchaseLoadingKeyProvider.notifier).state = null;
      }
    }
  }
}
