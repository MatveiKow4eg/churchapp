import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../models/user_stats_model.dart';
import '../stats_providers.dart';
import '../../../core/ui/task_category_i18n.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _didRedirect = false;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedStatsMonthProvider);
    final async = ref.watch(myStatsProvider);

    Future<void> onRefresh() async {
      // RefreshIndicator may complete after this widget is disposed.
      if (!mounted) return;
      await ref.read(myStatsProvider.notifier).refresh();
    }

    void prevMonth() {
      final dt = _parseYYYYMM(month);
      final prev = DateTime(dt.year, dt.month - 1, 1);
      ref.read(selectedStatsMonthProvider.notifier).state = _toYYYYMM(prev);
    }

    void nextMonth() {
      final dt = _parseYYYYMM(month);
      final next = DateTime(dt.year, dt.month + 1, 1);
      ref.read(selectedStatsMonthProvider.notifier).state = _toYYYYMM(next);
    }

    Widget body = async.when(
      data: (stats) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthSelector(
                title: _prettyMonth(stats.month),
                onPrev: prevMonth,
                onNext: nextMonth,
              ),
              const SizedBox(height: 12),
              _StatsGrid(stats: stats),
              const SizedBox(height: 16),
              if (stats.topCategories.isNotEmpty) ...[
                Text(
                  'Категории',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: stats.topCategories
                          .take(3)
                          .map((c) => _CategoryRow(category: c))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MonthSelector(
            title: _prettyMonth(month),
            onPrev: prevMonth,
            onNext: nextMonth,
          ),
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (err, st) {
        if (err is AppError && err.code == 'NO_CHURCH') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _didRedirect) return;
            _didRedirect = true;
            context.go(AppRoutes.church);
          });
        }

        if (err is AppError && err.code == 'UNAUTHORIZED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _didRedirect) return;
            _didRedirect = true;
            context.go(AppRoutes.register);
          });
        }

        final msg = (err is AppError && err.message.isNotEmpty)
            ? err.message
            : 'Не удалось загрузить статистику';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MonthSelector(
              title: _prettyMonth(month),
              onPrev: prevMonth,
              onNext: nextMonth,
            ),
            const SizedBox(height: 32),
            _ErrorState(
              message: msg,
              onRetry: () => ref.read(myStatsProvider.notifier).refresh(),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: body,
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Предыдущий месяц',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Следующий месяц',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final UserStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 520;

        final cards = [
          _StatCard(title: 'Выполнено', value: '${stats.tasksApprovedCount}'),
          _StatCard(title: 'Заработано', value: '${stats.pointsEarned}'),
          _StatCard(title: 'Потрачено', value: '${stats.pointsSpent}'),
          _StatCard(title: 'Баланс', value: '${stats.currentBalance}'),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[2],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    cards[1],
                    const SizedBox(height: 12),
                    cards[3],
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final UserTopCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.category.isEmpty
                  ? '—'
                  : localizeTaskCategory(category.category),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${category.count}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

DateTime _parseYYYYMM(String month) {
  final parts = month.split('-');
  final y = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? DateTime.now().year;
  final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? DateTime.now().month;
  return DateTime(y, m, 1);
}

String _toYYYYMM(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$y-$m';
}

String _prettyMonth(String monthYYYYMM) {
  final dt = _parseYYYYMM(monthYYYYMM);
  const names = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
  final m = (dt.month >= 1 && dt.month <= 12) ? names[dt.month - 1] : monthYYYYMM;
  return '$m ${dt.year}';
}

extension _SafeListExt<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
