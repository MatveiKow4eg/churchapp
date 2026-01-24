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
    final isSuperadmin = role == 'SUPERADMIN';

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
        children: [
          ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.fact_check_outlined),
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
            title: const Text('Заявки на проверку'),
            subtitle: const Text('Модерация заявок пользователей'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // When user opens the tab, refresh so the badge reflects the latest DB state.
              ref.read(pendingSubmissionsProvider.notifier).refresh();
              context.go(AppRoutes.adminPending);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.task_outlined),
            title: const Text('Задания'),
            subtitle: const Text('Создание и редактирование'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.adminTasks),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Предметы магазина'),
            subtitle: const Text('Скоро'),
            enabled: false,
            trailing: const Text('Скоро'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Статистика церкви'),
            subtitle: const Text('Отчёт по вашей церкви за месяц'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.adminChurchStats),
          ),
          if (isSuperadmin) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('SuperAdmin: церкви'),
              subtitle: const Text('Создание и список церквей'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('${AppRoutes.admin}/superadmin'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.people_alt_outlined),
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
              title: const Text('SuperAdmin: пользователи'),
              subtitle: const Text('Список и редактирование пользователей'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Ensure we have fresh state before opening the screen.
                ref.invalidate(superadminUsersProvider);
                context.go('${AppRoutes.admin}/superadmin-users');
              },
            ),
          ],
        ],
      ),
    );
  }
}
