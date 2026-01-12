import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';
import '../presentation/no_access_screen.dart';
import 'admin_task_actions_controller.dart';
import 'admin_tasks_providers.dart';
import '../../../core/ui/task_category_i18n.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  final Set<String> _selectedTaskIds = <String>{};
  bool _didRedirect = false;

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedTaskIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const NoAccessScreen();

    final async = ref.watch(adminTasksListProvider);
    final filter = ref.watch(adminTasksFilterProvider);
    final search = ref.watch(adminTasksSearchProvider);

    Future<void> onRefresh() async {
      await ref.read(adminTasksListProvider.notifier).refresh();
    }

    final hasSelection = _selectedTaskIds.isNotEmpty;

    void _handleBulkError(AppError e) {
      if (!mounted) return;

      if (e.code == 'NO_CHURCH') {
        if (_didRedirect) return;
        _didRedirect = true;
        context.go(AppRoutes.church);
        return;
      }

      if (e.code == 'UNAUTHORIZED') {
        if (_didRedirect) return;
        _didRedirect = true;
        context.go(AppRoutes.register);
        return;
      }

      final msg = e.code == 'FORBIDDEN'
          ? 'Нет доступа'
          : (e.message.isNotEmpty ? e.message : 'Ошибка');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> deleteSelected() async {
      final count = _selectedTaskIds.length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Удалить задания?'),
          content: Text('Будет удалено: $count'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        final ids = _selectedTaskIds.toList(growable: false);
        for (final id in ids) {
          await ref.read(adminTaskActionsControllerProvider.notifier).delete(id);
        }

        if (!mounted) return;
        _clearSelection();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Удалено: $count')),
        );
      } on AppError catch (e) {
        _handleBulkError(e);
      }
    }

    Future<void> deactivateSelected() async {
      final count = _selectedTaskIds.length;
      try {
        final ids = _selectedTaskIds.toList(growable: false);
        for (final id in ids) {
          await ref.read(adminTaskActionsControllerProvider.notifier).deactivate(id);
        }

        if (!mounted) return;
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Выключено: $count')),
        );
      } on AppError catch (e) {
        _handleBulkError(e);
      }
    }

    Future<void> activateSelected() async {
      final count = _selectedTaskIds.length;
      try {
        final ids = _selectedTaskIds.toList(growable: false);
        for (final id in ids) {
          await ref.read(adminTaskActionsControllerProvider.notifier).activate(id);
        }

        if (!mounted) return;
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Включено: $count')),
        );
      } on AppError catch (e) {
        _handleBulkError(e);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hasSelection ? 'Выбрано: ${_selectedTaskIds.length}' : 'Задания (админ)',
        ),
        leading: hasSelection
            ? IconButton(
                tooltip: 'Снять выделение',
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (hasSelection) ...[
            IconButton(
              tooltip: 'Включить выбранные',
              icon: const Icon(Icons.play_arrow_outlined),
              onPressed: activateSelected,
            ),
            IconButton(
              tooltip: 'Выключить выбранные',
              icon: const Icon(Icons.block_outlined),
              onPressed: deactivateSelected,
            ),
            IconButton(
              tooltip: 'Удалить выбранные',
              icon: const Icon(Icons.delete_outline),
              onPressed: deleteSelected,
            ),
          ] else
            IconButton(
              tooltip: 'Создать',
              onPressed: () => context.go('${AppRoutes.adminTasks}/new'),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      floatingActionButton: hasSelection
          ? FloatingActionButton.extended(
              onPressed: deactivateSelected,
              icon: const Icon(Icons.block_outlined),
              label: Text('Выключить (${_selectedTaskIds.length})'),
            )
          : null,
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
                        category: localizeTaskCategory(t.category),
                        pointsReward: t.pointsReward,
                        isActive: t.isActive,
                        isLoading: isLoading,
                        isSelected: _selectedTaskIds.contains(t.id),
                        onToggleSelected: () => _toggleSelected(t.id),
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
                      if (!mounted || _didRedirect) return;
                      _didRedirect = true;
                      context.go(AppRoutes.register);
                    });
                  }

                  if (appErr.code == 'NO_CHURCH') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _didRedirect) return;
                      _didRedirect = true;
                      context.go(AppRoutes.church);
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
    required this.isSelected,
    required this.onToggleSelected,
    required this.onEdit,
    required this.onDeactivate,
  });

  final String title;
  final String category;
  final int pointsReward;
  final bool isActive;
  final bool isLoading;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggleSelected,
        onLongPress: onToggleSelected,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelected(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                _Chip(
                  text: category.isEmpty
                      ? 'Без категории'
                      : localizeTaskCategory(category),
                ),
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
