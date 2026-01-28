import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/user_session_provider.dart';
import '../reports_api.dart';

final developerReportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  return ref.read(reportsApiProvider).listReports();
});

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

    final async = ref.watch(developerReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Репорты'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(developerReportsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Нет репортов'));
          }

          // Сортировка по дате: новые сверху
          final sorted = [...items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = sorted[i];
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
                    await ref.read(reportsApiProvider).deleteReport(id: r.id);
                    ref.invalidate(developerReportsProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Репорт удалён')),
                      );
                    }
                  } catch (e) {
                    // restore by reloading
                    ref.invalidate(developerReportsProvider);
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
