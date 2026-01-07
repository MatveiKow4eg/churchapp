import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/user_session_provider.dart';
import '../settings_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();

    final user = ref.read(userSessionProvider);
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('EditProfileScreen build');
    ref.listen<AsyncValue<void>>(settingsControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сохранено')),
          );
          // After successful save, return back to /settings.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.settings);
          }
        },
        error: (e, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    });

    final user = ref.watch(userSessionProvider);
    final controllerAsync = ref.watch(settingsControllerProvider);
    final isBusy = controllerAsync.isLoading;

    // Keep fields in sync if /auth/me updates.
    void sync(TextEditingController c, String nextText) {
      final hasFocus = FocusManager.instance.primaryFocus?.hasFocus ?? false;
      if (!hasFocus && c.text != nextText) {
        c.text = nextText;
      }
    }

    sync(_firstNameController, user?.firstName ?? '');
    sync(_lastNameController, user?.lastName ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Введите имя';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Введите фамилию';
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

                            debugPrint('EditProfile: before save location=${GoRouterState.of(context).matchedLocation}');
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .saveProfile(
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                // city stays unchanged from server; send null to skip update.
                                city: null,
                              );
                          if (!mounted) return;
                          debugPrint('EditProfile: after save location=${GoRouterState.of(context).matchedLocation}');
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
