import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/user_session_provider.dart';
import '../../auth/session_providers.dart';
import '../../../core/theme/theme_controller.dart';
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
          _ThemeSection(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Церковь'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.church_outlined),
            title: const Text('Текущая церковь'),
            subtitle: Text(churchLabel),
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
  // /auth/me кэшируется в currentUserProvider.
  // В мобильной модели UserModel сейчас нет поля `church`, есть только `churchId`.
  // Поэтому показываем "Не выбрано" или placeholder.
  final user = ref.watch(currentUserProvider).valueOrNull;

  if (user?.churchId == null) return 'Не выбрано';

  // Если позже добавим в UserModel поле churchName (или church), можно заменить.
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

class _ThemeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<AppThemeMode>(
          value: AppThemeMode.system,
          groupValue: themeState.mode,
          onChanged: (v) {
            if (v == null) return;
            ref.read(themeControllerProvider.notifier).setThemeMode(v);
          },
          title: const Text('Системная'),
        ),
        RadioListTile<AppThemeMode>(
          value: AppThemeMode.dark,
          groupValue: themeState.mode,
          onChanged: (v) {
            if (v == null) return;
            ref.read(themeControllerProvider.notifier).setThemeMode(v);
          },
          title: const Text('Тёмная'),
        ),
        RadioListTile<AppThemeMode>(
          value: AppThemeMode.light,
          groupValue: themeState.mode,
          onChanged: (v) {
            if (v == null) return;
            ref.read(themeControllerProvider.notifier).setThemeMode(v);
          },
          title: const Text('Светлая'),
        ),
        const SizedBox(height: 12),
        Text(
          'Акцентный цвет (опционально)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        _AccentColorPicker(
          selected: themeState.accentColor,
          onSelect: (c) =>
              ref.read(themeControllerProvider.notifier).setAccentColor(c),
        ),
      ],
    );
  }
}

class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.selected,
    required this.onSelect,
  });

  final Color selected;
  final ValueChanged<Color> onSelect;

  static const _options = <Color>[
    Colors.yellow,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = _options[index];
          final isSelected = color.value == selected.value;

          return InkWell(
            onTap: () => onSelect(color),
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: borderColor, width: 2)
                    : null,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color,
              ),
            ),
          );
        },
      ),
    );
  }
}
