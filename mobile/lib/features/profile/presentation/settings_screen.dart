import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/user_session_provider.dart';
import '../settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userSessionProvider);
    final churchName = ref.watch(_currentChurchNameProvider);

    final controllerAsync = ref.watch(settingsControllerProvider);
    final isBusy = controllerAsync.isLoading;

    final churchLabel = churchName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Редактировать профиль'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Имя и фамилия'),
            subtitle: Text(
              '${(user?.firstName ?? '').trim()} ${(user?.lastName ?? '').trim()}'.trim().isEmpty
                  ? 'Не заполнено'
                  : '${(user?.firstName ?? '').trim()} ${(user?.lastName ?? '').trim()}'.trim(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsEditProfile),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Настройки безопасности'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Сменить пароль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsChangePassword),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Сменить email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsChangeEmail),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Тема'),
          const SizedBox(height: 8),
          const _DisabledOption(
            title: 'Темная тема',
            subtitle: '(в разработке)',
          ),
          const _DisabledOption(
            title: 'Светлая',
            subtitle: '(в разработке)',
          ),
          const _DisabledOption(
            title: 'Системная',
            subtitle: '(в разработке)',
          ),
          const _DisabledOption(
            title: 'Акцентный цвет',
            subtitle: '(опционально, в разработке)',
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Церковь'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.church_outlined),
            title: const Text('Текущая церковь'),
            subtitle: Text(churchLabel),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Сменить церковь'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.church),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (isBusy || user?.churchId == null)
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Выйти из церкви?'),
                        content: const Text(
                          'Вы потеряете доступ к заданиям этой церкви. Продолжить?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Выйти'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    await ref
                        .read(settingsControllerProvider.notifier)
                        .leaveChurch();

                    if (!context.mounted) return;
                    context.go(AppRoutes.church);
                  },
            icon: isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Выйти из церкви'),
          ),
        ],
      ),
    );
  }
}

final _currentChurchNameProvider = Provider<String>((ref) {
  // /auth/me may return church, but currentUserProvider stores only user for now.
  // Showing "..." when churchId exists keeps UI consistent without extra API.
  final user = ref.watch(userSessionProvider);
  if (user?.churchId == null) return 'Не выбрано';
  return '...';
});

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DisabledOption extends StatelessWidget {
  const _DisabledOption({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.lock_outline),
    );
  }
}
