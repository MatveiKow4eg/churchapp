import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/user_session_provider.dart';
import 'pending_submissions_providers.dart';
import '../../superadmin/superadmin_providers.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = (ref.watch(userRoleProvider) ?? '').trim().toUpperCase();
    final isSuperadmin = role == 'SUPERADMIN' || role == 'DEVELOPER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            minVerticalPadding: 18,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.fact_check_outlined, size: 26),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final async = ref.watch(pendingSubmissionsProvider);
                      final count = async.maybeWhen(
                        data: (items) => items.length,
                        orElse: () => 0,
                      );

                      if (count <= 0) return const SizedBox.shrink();

                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            title: const Text(
              'Заявки на проверку',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () {
              // When user opens the tab, refresh so the badge reflects the latest DB state.
              ref.read(pendingSubmissionsProvider.notifier).refresh();
              context.go(AppRoutes.adminPending);
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            minVerticalPadding: 18,
            leading: const Icon(Icons.task_outlined, size: 26),
            title: const Text(
              'Задания',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () => context.go(AppRoutes.adminTasks),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            minVerticalPadding: 18,
            leading: const Icon(Icons.storefront_outlined, size: 26),
            title: const Text(
              'Предметы магазина',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            enabled: false,
            trailing: const Text(
              'Скоро',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            minVerticalPadding: 18,
            leading: const Icon(Icons.bar_chart_outlined, size: 26),
            title: const Text(
              'Статистика церкви',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, size: 26),
            onTap: () => context.go(AppRoutes.adminChurchStats),
          ),
          if (isSuperadmin) ...[
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              minVerticalPadding: 18,
              leading: const Icon(Icons.admin_panel_settings_outlined, size: 26),
              title: const Text(
                'SuperAdmin/Developer: церкви',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 26),
              onTap: () => context.go('${AppRoutes.admin}/superadmin'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              minVerticalPadding: 18,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.people_alt_outlined, size: 26),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final usersAsync = ref.watch(superadminUsersProvider);
                        final countNew = usersAsync.maybeWhen(
                          data: (users) {
                            final now = DateTime.now();
                            return users.where((u) {
                              final age = now.difference(u.createdAt);
                              return age.inDays < 3;
                            }).length;
                          },
                          orElse: () => 0,
                        );

                        if (countNew <= 0) return const SizedBox.shrink();

                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              title: const Text(
                'SuperAdmin/Developer: пользователи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 26),
              onTap: () {
                // Ensure we have fresh state before opening the screen.
                ref.invalidate(superadminUsersProvider);
                context.go('${AppRoutes.admin}/superadmin-users');
              },
            ),
            if (role == 'DEVELOPER') ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                minVerticalPadding: 18,
                leading: const Icon(Icons.bug_report_outlined, size: 26),
                title: const Text(
                  'Репорты',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, size: 26),
                onTap: () => context.go(AppRoutes.developerReports),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
