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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final title = r.userName;
              final subtitle = [
                if (r.userEmail.trim().isNotEmpty) r.userEmail.trim(),
                r.createdAt.toLocal().toString(),
                '',
                r.text.trim(),
              ].join('\n');

              return ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(title),
                subtitle: Text(subtitle),
                isThreeLine: true,
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
