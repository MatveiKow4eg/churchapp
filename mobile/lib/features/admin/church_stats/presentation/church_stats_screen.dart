import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_error.dart';
import '../church_stats_providers.dart';
import '../models/church_stats_model.dart';

import '../../../avatar/presentation/avatar_thumb_image.dart';
import '../../../avatar/dicebear/dicebear_url.dart';
import '../../../../core/providers/providers.dart';

class ChurchStatsScreen extends ConsumerStatefulWidget {
  const ChurchStatsScreen({super.key});

  @override
  ConsumerState<ChurchStatsScreen> createState() => _ChurchStatsScreenState();
}

class _ChurchStatsScreenState extends ConsumerState<ChurchStatsScreen> {
  bool _didRedirect = false;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedChurchStatsMonthProvider);
    final async = ref.watch(churchStatsProvider);

    Future<void> onRefresh() async {
      if (!mounted) return;
      await ref.read(churchStatsProvider.notifier).refresh();
    }

    void prevMonth() {
      final dt = _parseYYYYMM(month);
      final prev = DateTime(dt.year, dt.month - 1, 1);
      ref.read(selectedChurchStatsMonthProvider.notifier).state = _toYYYYMM(prev);
    }

    void nextMonth() {
      final dt = _parseYYYYMM(month);
      final next = DateTime(dt.year, dt.month + 1, 1);
      ref.read(selectedChurchStatsMonthProvider.notifier).state = _toYYYYMM(next);
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
              if (stats.topUsers.isNotEmpty) ...[
                Text(
                  'Топ пользователей (net points)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (final u in stats.topUsers) _TopUserRow(item: u),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (stats.topTasks.isNotEmpty) ...[
                Text(
                  'Топ заданий (APPROVED)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (final t in stats.topTasks) _TopTaskRow(item: t),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Все участники церкви',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: stats.members.isEmpty
                      ? const Text('Пока нет участников')
                      : Column(
                          children: [
                            for (final m in stats.members) _MemberRow(member: m),
                          ],
                        ),
                ),
              ),
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

        if (err is AppError && err.code == 'FORBIDDEN') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _didRedirect) return;
            _didRedirect = true;
            context.go(AppRoutes.forbidden);
          });
        }

        final msg = (err is AppError && err.message.isNotEmpty)
            ? err.message
            : 'Не удалось загрузить статистику церкви';

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
              onRetry: () => ref.read(churchStatsProvider.notifier).refresh(),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика церкви'),
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.admin);
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

  final ChurchStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 520;

        final cards = [
          _StatCard(title: 'Активных', value: '${stats.activeUsersCount}'),
          _StatCard(
            title: 'Общий онлайн',
            // пока нет реального presence: считаем online = ACTIVE
            value: '${stats.activeUsersCount}',
          ),
          _StatCard(title: 'Одобрено', value: '${stats.approvedSubmissionsCount}'),
          _StatCard(title: 'В очереди', value: '${stats.pendingSubmissionsCount}'),
          _StatCard(title: 'Net points', value: '${stats.netPoints}'),
          _StatCard(title: 'Заработано', value: '${stats.totalPointsEarned}'),
          _StatCard(title: 'Потрачено', value: '${stats.totalPointsSpent}'),
          _StatCard(
            title: 'Всего участников',
            value: '${stats.totalMembersCount}',
          ),
        ];

        // Render as a responsive 2-column grid (works for 6, 8, etc. cards)
        Widget gridFor(List<Widget> items) {
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += 2) {
            final left = items[i];
            final right = (i + 1 < items.length) ? items[i + 1] : const SizedBox();

            rows.add(
              Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              ),
            );

            if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
          }
          return Column(children: rows);
        }

        return gridFor(cards);
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

class _TopUserRow extends ConsumerWidget {
  const _TopUserRow({required this.item});

  final ChurchTopUser item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseUrl = ref.watch(appConfigProvider).baseUrl;

    Uri? avatarUrl;
    final cfg = item.user.avatarConfig;
    if (cfg != null && cfg.isNotEmpty) {
      avatarUrl = buildAdventurerPngUrl(baseUrl, cfg);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: avatarUrl != null
                  ? AvatarThumbImage(url: avatarUrl, fit: BoxFit.cover, cacheWidth: 96)
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.user.fullName,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${item.netPoints}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member});

  final ChurchMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseUrl = ref.watch(appConfigProvider).baseUrl;

    Uri? avatarUrl;
    final cfg = member.avatarConfig;
    if (cfg != null && cfg.isNotEmpty) {
      avatarUrl = buildAdventurerPngUrl(baseUrl, cfg);
    }

    final statusText = member.status.trim().isEmpty ? '—' : member.status.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: avatarUrl != null
                  ? AvatarThumbImage(
                      url: avatarUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 96,
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTaskRow extends StatelessWidget {
  const _TopTaskRow({required this.item});

  final ChurchTopTask item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = item.task.title.trim().isEmpty ? '—' : item.task.title.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${item.approvedCount}',
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
