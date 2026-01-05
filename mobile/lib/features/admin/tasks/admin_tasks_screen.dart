import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';
import '../presentation/no_access_screen.dart';
import 'admin_task_actions_controller.dart';
import 'admin_tasks_providers.dart';

class AdminTasksScreen extends ConsumerWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const NoAccessScreen();

    final async = ref.watch(adminTasksListProvider);
    final filter = ref.watch(adminTasksFilterProvider);
    final search = ref.watch(adminTasksSearchProvider);

    Future<void> onRefresh() async {
      await ref.read(adminTasksListProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания (админ)'),
        actions: [
          IconButton(
            tooltip: 'Создать',
            onPressed: () => context.go('${AppRoutes.adminTasks}/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${AppRoutes.adminTasks}/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  ref.read(adminTasksSearchProvider.notifier).state = v,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск по названию',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AdminTasksFilter>(
              segments: const [
                ButtonSegment(
                  value: AdminTasksFilter.all,
                  label: Text('Все'),
                ),
                ButtonSegment(
                  value: AdminTasksFilter.active,
                  label: Text('Активные'),
                ),
                ButtonSegment(
                  value: AdminTasksFilter.inactive,
                  label: Text('Выключенные'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (s) {
                ref.read(adminTasksFilterProvider.notifier).state = s.first;
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              data: (items) {
                final filtered = items.where((t) {
                  final okSearch = search.trim().isEmpty ||
                      t.title.toLowerCase().contains(search.trim().toLowerCase());
                  final okFilter = switch (filter) {
                    AdminTasksFilter.all => true,
                    AdminTasksFilter.active => t.isActive,
                    AdminTasksFilter.inactive => !t.isActive,
                  };
                  return okSearch && okFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        _EmptyState(),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      final loadingIds =
                          ref.watch(adminTaskActionsControllerProvider);
                      final isLoading = loadingIds.contains(t.id);

                      return _TaskAdminCard(
                        title: t.title,
                        category: t.category,
                        pointsReward: t.pointsReward,
                        isActive: t.isActive,
                        isLoading: isLoading,
                        onEdit: () => context.go(
                            '${AppRoutes.adminTasks}/${t.id}/edit'),
                        onDeactivate: t.isActive
                            ? () async {
                                try {
                                  await ref
                                      .read(adminTaskActionsControllerProvider
                                          .notifier)
                                      .deactivate(t.id);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Задание выключено')),
                                    );
                                  }
                                } on AppError catch (e) {
                                  if (!context.mounted) return;

                                  if (e.code == 'NO_CHURCH') {
                                    context.go(AppRoutes.church);
                                    return;
                                  }

                                  if (e.code == 'UNAUTHORIZED') {
                                    context.go(AppRoutes.register);
                                    return;
                                  }

                                  final msg = e.code == 'FORBIDDEN'
                                      ? 'Нет доступа'
                                      : (e.message.isNotEmpty
                                          ? e.message
                                          : 'Ошибка');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) {
                final appErr = err is AppError ? err : null;

                if (appErr != null) {
                  if (appErr.code == 'UNAUTHORIZED') {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await ref
                          .read(adminTasksListProvider.notifier)
                          .handleAppError(appErr);
                      if (context.mounted) context.go(AppRoutes.register);
                    });
                  }

                  if (appErr.code == 'NO_CHURCH') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) context.go(AppRoutes.church);
                    });
                  }

                  if (appErr.code == 'FORBIDDEN') {
                    return _ForbiddenState(onBack: () => context.pop());
                  }
                }

                final msg = appErr?.message ?? err.toString();
                return _ErrorState(
                  message: msg.isNotEmpty
                      ? msg
                      : 'Не удалось загрузить список заданий',
                  onRetry: () =>
                      ref.read(adminTasksListProvider.notifier).refresh(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskAdminCard extends StatelessWidget {
  const _TaskAdminCard({
    required this.title,
    required this.category,
    required this.pointsReward,
    required this.isActive,
    required this.isLoading,
    required this.onEdit,
    required this.onDeactivate,
  });

  final String title;
  final String category;
  final int pointsReward;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                _Badge(
                  text: isActive ? 'Активно' : 'Выключено',
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(text: category.isEmpty ? 'Без категории' : category),
                const SizedBox(width: 8),
                _Chip(text: '+$pointsReward очков'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Редактировать'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onDeactivate,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_outlined),
                    label: Text(isLoading ? '...' : 'Выключить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

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
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Заданий не найдено',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Попробуй изменить фильтр или поиск.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _ForbiddenState extends StatelessWidget {
  const _ForbiddenState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Нет доступа',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'У твоего аккаунта нет прав дл�� управления заданиями.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}
