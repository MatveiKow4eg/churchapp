import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/catalog_item.dart';
import '../inventory_providers.dart';
import '../models/server_inventory_item.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCatalog = ref.watch(catalogProvider);
    final asyncInv = ref.watch(serverInventoryProvider);

    Future<void> onRefresh() async {
      ref.invalidate(serverInventoryProvider);
      ref.invalidate(catalogProvider);
    }

    Widget body;

    if (asyncCatalog.isLoading || asyncInv.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (asyncCatalog.hasError) {
      body = _ErrorState(
        message: 'Не удалось загрузить каталог',
        onRetry: () => ref.invalidate(catalogProvider),
      );
    } else if (asyncInv.hasError) {
      final err = asyncInv.error;

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

      body = _ErrorState(
        message: msg,
        onRetry: () => ref.invalidate(serverInventoryProvider),
      );
    } else {
      final catalog = asyncCatalog.value ?? const <CatalogItem>[];
      final inv = asyncInv.value ?? const <ServerInventoryItem>[];

      final byKey = <String, CatalogItem>{
        for (final c in catalog) c.key: c,
      };

      if (inv.isEmpty) {
        body = const _EmptyState();
      } else {
        final crossAxisCount =
            MediaQuery.of(context).size.shortestSide >= 600 ? 3 : 2;

        body = RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: inv.length,
            itemBuilder: (context, i) {
              final item = inv[i];
              final catalogItem = byKey[item.itemKey];
              return _InventoryGridCard(inv: item, catalogItem: catalogItem);
            },
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентарь'),
      ),
      body: body,
    );
  }
}

class _InventoryGridCard extends StatelessWidget {
  const _InventoryGridCard({required this.inv, required this.catalogItem});

  final ServerInventoryItem inv;
  final CatalogItem? catalogItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = catalogItem?.displayName(locale: 'ru') ?? 'Unknown item';
    final iconPath = catalogItem?.iconPath;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: iconPath == null
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.help_outline),
                      )
                    : Image.asset(
                        iconPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, st) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'x${inv.quantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Куплено: ${_format(inv.acquiredAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    return '$y-$m-$d';
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
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
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
