import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../inventory_providers.dart';
import '../models/inventory_item_model.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryItemsProvider);

    Future<void> onRefresh() async {
      await ref.read(inventoryItemsProvider.notifier).refresh();
    }

    Widget body = async.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final inv = items[i];
              return _InventoryCard(inv: inv);
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
            : 'Не удалось загрузить инвентарь';

        return _ErrorState(
          message: msg,
          onRetry: () => ref.read(inventoryItemsProvider.notifier).refresh(),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентарь'),
      ),
      body: body,
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.inv});

  final InventoryItemModel inv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final item = inv.item;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name.isEmpty ? 'Предмет' : item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'x${inv.quantity}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeBadge(text: item.type.isEmpty ? '—' : item.type),
                const Spacer(),
                Text(
                  'Куплено: ${_format(inv.acquiredAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Пока нет предметов',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Загляни в магазин!',
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
