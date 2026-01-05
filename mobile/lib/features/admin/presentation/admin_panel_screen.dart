import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ-панель')),
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
            subtitle: const Text('Скоро'),
            enabled: false,
            trailing: const Text('Скоро'),
          ),
        ],
      ),
    );
  }
}
