import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/errors/app_error.dart';
import 'my_submissions_providers.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mySubmissionsFilterProvider);
    final async = ref.watch(mySubmissionsListProvider);

    Widget chips = Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Все'),
          selected: filter == MySubmissionsFilter.all,
          onSelected: (_) {
            ref.read(mySubmissionsFilterProvider.notifier).state =
                MySubmissionsFilter.all;
            ref.invalidate(mySubmissionsListProvider);
          },
        ),
        ChoiceChip(
          label: const Text('Ожидает'),
          selected: filter == MySubmissionsFilter.pending,
          onSelected: (_) {
            ref.read(mySubmissionsFilterProvider.notifier).state =
                MySubmissionsFilter.pending;
            ref.invalidate(mySubmissionsListProvider);
          },
        ),
        ChoiceChip(
          label: const Text('Подтверждено'),
          selected: filter == MySubmissionsFilter.approved,
          onSelected: (_) {
            ref.read(mySubmissionsFilterProvider.notifier).state =
                MySubmissionsFilter.approved;
            ref.invalidate(mySubmissionsListProvider);
          },
        ),
        ChoiceChip(
          label: const Text('Отклонено'),
          selected: filter == MySubmissionsFilter.rejected,
          onSelected: (_) {
            ref.read(mySubmissionsFilterProvider.notifier).state =
                MySubmissionsFilter.rejected;
            ref.invalidate(mySubmissionsListProvider);
          },
        ),
      ],
    );

    Future<void> onRefresh() async {
      await ref.read(mySubmissionsListProvider.notifier).refresh();
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
              final s = items[i];
              final task = s.task;

              final statusWidget = _StatusChip(status: s.status);

              final pointsText = switch (s.status) {
                'APPROVED' => '+${s.rewardPointsApplied ?? 0}',
                'PENDING' => '+${task?.pointsReward ?? 0} (ожидается)',
                'REJECTED' => '0',
                _ => '0',
              };

              final created = _formatDate(s.createdAt);
              final decided =
                  s.decidedAt == null ? null : _formatDate(s.decidedAt!);

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
                              task?.title ?? 'Задание',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            pointsText,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Badge(text: task?.category ?? '—'),
                          const SizedBox(width: 8),
                          statusWidget,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        decided == null
                            ? 'Создано: $created'
                            : 'Создано: $created  •  Решено: $decided',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if ((s.commentAdmin ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Комментарий: ${s.commentAdmin}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
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

        final message = (err is AppError && err.message.isNotEmpty)
            ? err.message
            : 'Не удалось загрузить заявки';

        return _ErrorState(
          message: message,
          onRetry: () => ref.read(mySubmissionsListProvider.notifier).refresh(),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заявки')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: chips,
            ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    late final Color bg;
    late final Color fg;
    late final String text;
    late final IconData icon;

    switch (status) {
      case 'PENDING':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        text = 'Ожидает';
        icon = Icons.hourglass_top;
        break;
      case 'APPROVED':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'Подтверждено';
        icon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        text = 'Отклонено';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        text = status;
        icon = Icons.info_outline;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
            Icon(Icons.inbox_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Пока нет заявок',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Когда ты отправишь выполнение задания на проверку, оно появится здесь.',
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
