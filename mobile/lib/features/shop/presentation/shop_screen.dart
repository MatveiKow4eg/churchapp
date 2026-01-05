import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../inventory/inventory_providers.dart';
import '../models/shop_item_model.dart';
import '../shop_providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopItemsProvider);
    final balance = ref.watch(balanceProvider);
    final ownedItemIds = ref.watch(ownedItemIdsProvider);
    final purchasingItemId = ref.watch(purchaseLoadingItemIdProvider);

    Future<void> onRefresh() async {
      await ref.read(shopItemsProvider.notifier).refresh();
    }

    Widget body = async.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _BalanceCard(balance: balance);
              }

              final item = items[i - 1];
              final isOwned = ownedItemIds.contains(item.id);
              final isLoading = purchasingItemId == item.id;

              return _ShopItemCard(
                item: item,
                isOwned: isOwned,
                isLoading: isLoading,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) {
        if (err is AppError && err.code == 'NO_CHURCH') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.church);
          });
        }

        if (err is AppError && err.code == 'UNAUTHORIZED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.register);
          });
        }

        final msg = (err is AppError && err.message.isNotEmpty)
            ? err.message
            : 'Не удалось загрузить магазин';

        return _ErrorState(
          message: msg,
          onRetry: () => ref.read(shopItemsProvider.notifier).refresh(),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        actions: [
          IconButton(
            tooltip: 'Статистика',
            onPressed: () => context.go(AppRoutes.stats),
            icon: const Icon(Icons.bar_chart_outlined),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.inventory),
            child: const Text('Инвентарь'),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int? balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Баланс: ${balance ?? '—'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopItemCard extends ConsumerWidget {
  const _ShopItemCard({
    required this.item,
    required this.isOwned,
    required this.isLoading,
  });

  final ShopItemModel item;
  final bool isOwned;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final String name = item.name;
    final String description = item.description;
    final String type = item.type;
    final int pricePoints = item.pricePoints;

    Future<void> buy() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Подтверди покупку'),
            content: Text('Купить $name за $pricePoints очков?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Купить'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final rootScaffoldMessenger = ScaffoldMessenger.of(context);
      final rootRouter = GoRouter.of(context);

      ref.read(purchaseLoadingItemIdProvider.notifier).state = item.id;

      try {
        final repo = ref.read(shopRepositoryProvider);
        final result = await repo.purchaseItem(item.id);

        // Cache balance locally (we don't fetch /me/balance yet).
        ref.read(balanceProvider.notifier).state = result.balance;

        // Refresh inventory (source of truth) + owned item ids.
        await ref.read(inventoryItemsProvider.notifier).refresh();

        rootScaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Куплено!')));
      } on AppError catch (e) {
        if (e.code == 'NO_CHURCH') {
          rootRouter.go(AppRoutes.church);
          return;
        }
        if (e.code == 'UNAUTHORIZED') {
          rootRouter.go(AppRoutes.register);
          return;
        }

        final msgLower = e.message.toLowerCase();
        final msg = msgLower.contains('insufficient')
            ? 'Недостаточно очков'
            : msgLower.contains('already owned')
                ? 'Уже куплено'
                : msgLower.contains('item inactive')
                    ? 'Предмет недоступен'
                    : (e.message.isNotEmpty ? e.message : 'Ошибка сети');

        rootScaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      } catch (_) {
        rootScaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Ошибка сети')));
      } finally {
        final current = ref.read(purchaseLoadingItemIdProvider);
        if (current == item.id) {
          ref.read(purchaseLoadingItemIdProvider.notifier).state = null;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty ? 'Предмет' : name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Цена: $pricePoints',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeBadge(text: type.isEmpty ? '—' : type),
                const Spacer(),
                FilledButton(
                  onPressed: (isOwned || isLoading) ? null : buy,
                  child: isOwned
                      ? const Text('Куплено')
                      : (isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Купить')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _BalanceCard(balance: null),
        SizedBox(height: 48),
        _EmptyBody(),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Пока нет предметов',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Загляни позже — магазин скоро пополнится.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
