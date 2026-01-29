import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/user_session_provider.dart';
import '../reports_api.dart';

final developerReportsControllerProvider =
    NotifierProvider<DeveloperReportsController, AsyncValue<List<ReportItem>>>(
  DeveloperReportsController.new,
);

class DeveloperReportsController extends Notifier<AsyncValue<List<ReportItem>>> {
  @override
  AsyncValue<List<ReportItem>> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await ref.read(reportsApiProvider).listReports();
      // Сортировка по дате: новые сверху
      final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    });
  }

  Future<void> refresh() => _load();

  Future<void> deleteById(String id) async {
    final previous = state;

    // ВАЖНО: Dismissible требует убрать элеме��т из дерева сразу после dismiss.
    state = state.whenData((items) => items.where((r) => r.id != id).toList());

    try {
      await ref.read(reportsApiProvider).deleteReport(id: id);
    } catch (e, st) {
      // Откатываем UI, если серверное удаление не прошло
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}

class DeveloperReportsScreen extends ConsumerWidget {
  const DeveloperReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = (ref.watch(userRoleProvider) ?? '').trim().toUpperCase();
    if (role != 'DEVELOPER') {
      return const Scaffold(
        body: Center(child: Text('Forbidden: DEVELOPER only')),
      );
    }

    final async = ref.watch(developerReportsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Репорты'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () =>
                ref.read(developerReportsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Нет репортов'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final dt = r.createdAt.toLocal();
              final email = r.userEmail.trim();
              final text = r.text.trim();

              final preview = text.isEmpty
                  ? ''
                  : (text.length > 90 ? '${text.substring(0, 90)}…' : text);

              return Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить репорт?'),
                          content: const Text('Действие нельзя отменить.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Удалить'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  try {
                    await ref
                        .read(developerReportsControllerProvider.notifier)
                        .deleteById(r.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Репорт удалён')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Не удалось удалить: $e')),
                      );
                    }
                  }
                },
                child: ExpansionTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(r.userName),
                  subtitle: Text(
                    [
                      if (email.isNotEmpty) email,
                      dt.toString(),
                      if (preview.isNotEmpty) preview,
                    ].join('\n'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Пользователь: ${r.userName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (email.isNotEmpty) Text('Email: $email'),
                          Text('Дата: $dt'),
                          const SizedBox(height: 10),
                          Text(text.isEmpty ? '—' : text),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Не удалось загрузить: $e'),
          ),
        ),
      ),
    );
  }
}
