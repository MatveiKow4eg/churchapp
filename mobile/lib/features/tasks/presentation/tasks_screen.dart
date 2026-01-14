import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../avatar/avatar_providers.dart';
import '../../avatar/presentation/avatar_thumb_image.dart';
import '../../../core/errors/app_error.dart';
import '../../tasks/tasks_providers.dart';
import '../../auth/user_session_provider.dart';
import '../../../core/ui/task_category_i18n.dart';
import '../../../core/ui/bible_refs.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _didRedirect = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('TasksScreen build');
    final async = ref.watch(tasksListProvider);

    Future<void> onRefresh() async {
      // RefreshIndicator can complete after this widget is disposed (e.g. user
      // navigated away while the refresh Future was running).
      if (!mounted) return;
      await ref.read(tasksListProvider.notifier).refresh();
    }

    void goShop() => context.go(AppRoutes.shop);
    void goStats() => context.go(AppRoutes.stats);

    Widget body;

    body = async.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyState(
            title: 'Пока нет заданий',
            subtitle: 'Загляни позже — скоро появятся новые задания.',
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = items[i];
              return _TaskCard(
                title: t.title,
                description: stripBibleRefsFromDescription(t.description),
                category: localizeTaskCategory(t.category),
                pointsReward: t.pointsReward,
                onDetails: () {
                  context.go('${AppRoutes.tasks}/${t.id}');
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) {
        final msg = err is AppError ? err.message : err.toString();

        // Handle special cases
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

        return _ErrorState(
          message: msg.isNotEmpty ? msg : 'Не удалось загрузить задания',
          onRetry: () => ref.read(tasksListProvider.notifier).refresh(),
        );
      },
    );

    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания'),
        leading: IconButton(
          tooltip: 'Профиль',
          onPressed: () => context.go(AppRoutes.profile),
          icon: _AvatarLeading(),
        ),
      ),
      body: body,
    );
  }
}

class _AvatarLeading extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(avatarPreviewUrlProvider);

    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: AvatarThumbImage(
          url: url,
          fit: BoxFit.cover,
          cacheWidth: 64,
        ),
      ),
    );
  }
}


class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.description,
    required this.category,
    required this.pointsReward,
    required this.onDetails,
  });

  final String title;
  final String description;
  final String category;
  final int pointsReward;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+$pointsReward очков',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Badge(text: category.isEmpty ? 'Без категории' : category),
                  const Spacer(),
                  TextButton(
                    onPressed: onDetails,
                    child: const Text('Подробнее'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
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
