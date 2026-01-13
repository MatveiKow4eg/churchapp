import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/user_session_provider.dart';

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
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Заявки на проверку'),
            subtitle: const Text('Модерация заявок пользователей'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.adminPending),
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
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('SuperAdmin: пользователи'),
              subtitle: const Text('Список и редактирование пользователей'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('${AppRoutes.admin}/superadmin-users'),
            ),
          ],
        ],
      ),
    );
  }
}
