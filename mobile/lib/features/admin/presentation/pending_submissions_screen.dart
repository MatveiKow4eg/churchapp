import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';
import '../../submissions/models/pending_submission_item.dart';
import 'no_access_screen.dart';
import 'pending_submissions_providers.dart';
import 'submission_actions_controller.dart';

class PendingSubmissionsScreen extends ConsumerWidget {
  const PendingSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extra safety: screen should be accessible only for admins.
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const NoAccessScreen();

    final async = ref.watch(pendingSubmissionsProvider);

    Future<void> onRefresh() async {
      await ref.read(pendingSubmissionsProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Проверка заданий')),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
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
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = items[i];

                final loadingIds =
                    ref.watch(submissionActionsControllerProvider);
                final isActionLoading = loadingIds.contains(item.id);

                return _PendingCard(
                  item: item,
                  isLoading: isActionLoading,
                  onApprove: () async {
                    final comment = await _showActionDialog(
                      context,
                      title: 'Подтвердить заявку',
                      actionLabel: 'Подтвердить',
                    );
                    if (comment == null) return;

                    try {
                      final res = await ref
                          .read(submissionActionsControllerProvider.notifier)
                          .approve(item.id, commentAdmin: comment);

                      final points = res.submission.rewardPointsApplied ??
                          item.task.pointsReward;
                      final balance = res.balance;

                      final text = balance == null
                          ? 'Подтверждено, начислено +$points'
                          : 'Подтверждено, начислено +$points • Баланс: $balance';

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(text)),
                        );
                      }
                    } on AppError catch (e) {
                      if (!context.mounted) return;
                      final msg = _mapActionError(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );

                      if (e.code == 'UNAUTHORIZED') {
                        context.go(AppRoutes.register);
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  onReject: () async {
                    final comment = await _showActionDialog(
                      context,
                      title: 'Отклонить заявку',
                      actionLabel: 'Отклонить',
                    );
                    if (comment == null) return;

                    try {
                      await ref
                          .read(submissionActionsControllerProvider.notifier)
                          .reject(item.id, commentAdmin: comment);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Отклонено')),
                        );
                      }
                    } on AppError catch (e) {
                      if (!context.mounted) return;
                      final msg = _mapActionError(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );

                      if (e.code == 'UNAUTHORIZED') {
                        context.go(AppRoutes.register);
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) {
          final appErr = err is AppError ? err : null;
          final message = appErr?.message ?? err.toString();

          // Auth/session routing
          if (appErr != null) {
            // 401 -> logout -> redirect rules will send to /register
            if (appErr.code == 'UNAUTHORIZED') {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref
                    .read(pendingSubmissionsProvider.notifier)
                    .handleAppError(appErr);
                if (context.mounted) context.go(AppRoutes.register);
              });
            }

            // 409 NO_CHURCH -> /church
            if (appErr.code == 'NO_CHURCH') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.church);
              });
            }

            // 403 -> show no-access UI with back
            if (appErr.code == 'FORBIDDEN') {
              return _ForbiddenState(
                onBack: () => context.pop(),
              );
            }
          }

          return _ErrorState(
            message: message.isNotEmpty
                ? message
                : 'Не удалось загрузить заявки на проверку',
            onRetry: () => ref.read(pendingSubmissionsProvider.notifier).refresh(),
          );
        },
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.item,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  final PendingSubmissionItem item;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final userLine = '${item.user.fullName}, ${item.user.age} • ${item.user.city}'.trim();
    final taskLine = item.task.title.isEmpty
        ? 'Задание'
        : item.task.title;

    final dateStr = _formatDate(item.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              userLine,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    taskLine,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${item.task.pointsReward} очков',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if ((item.commentUser ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    item.commentUser!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              dateStr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onApprove,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isLoading ? '...' : 'Подтвердить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Отклонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final two = (int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} • ${two(d.hour)}:${two(d.minute)}';
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
            Icon(Icons.inbox_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Пока нет заявок',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Потяни вниз, чтобы обновить.',
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

Future<String?> _showActionDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) async {
  final controller = TextEditingController();

  final res = await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: 300,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Комментарий (необязательно)',
            hintText: 'Например: всё ок / не засчитано потому что...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );

  // If user canceled -> null.
  if (res == null) return null;

  // If empty comment -> return null? We return empty string (treated as absent)
  // so caller can proceed.
  return res;
}

String _mapActionError(AppError e) {
  if (e.code == 'CONFLICT') return 'Заявка уже обработана';
  if (e.code == 'FORBIDDEN') return 'Нет доступа';
  if (e.code == 'UNAUTHORIZED') return 'Сессия истекла. Войди снова.';

  final msg = e.message.trim();
  return msg.isEmpty ? 'Ошибка' : msg;
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
              'У твоего аккаунта нет прав для проверки заявок.',
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
