import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _newRepeatController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureRepeat = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _newRepeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(settingsControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароль обновлён')),
          );
          Navigator.of(context).maybePop();
        },
        error: (e, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    });

    final isBusy = ref.watch(settingsControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Сменить пароль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _currentController,
                  decoration: InputDecoration(
                    labelText: 'Текущий пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  obscureText: _obscureCurrent,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите текущий пароль';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  obscureText: _obscureNew,
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Введите новый пароль';
                    if (value.length < 6) return 'Минимум 6 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newRepeatController,
                  decoration: InputDecoration(
                    labelText: 'Повторите новый пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureRepeat = !_obscureRepeat),
                      icon: Icon(_obscureRepeat ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  obscureText: _obscureRepeat,
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Повторите новый пароль';
                    if (v != _newController.text) return 'Пароли не совпадают';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final ok = _formKey.currentState?.validate() ?? false;
                            if (!ok) return;

                            await ref.read(settingsControllerProvider.notifier).changePassword(
                                  currentPassword: _currentController.text,
                                  newPassword: _newController.text,
                                );
                          },
                    child: isBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
