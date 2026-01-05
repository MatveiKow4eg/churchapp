import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/tasks_providers.dart';
import '../presentation/no_access_screen.dart';
import 'admin_tasks_providers.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();

  String _category = 'GENERAL';
  bool _saving = false;
  bool _loadedOnce = false;
  bool _isActive = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _fill(TaskModel t) {
    _titleCtrl.text = t.title;
    _descCtrl.text = t.description;
    _pointsCtrl.text = t.pointsReward.toString();
    _category = t.category.isEmpty ? 'GENERAL' : t.category;
    _isActive = t.isActive;
  }

  String? _validateTitle(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Введите название';
    if (s.length < 3) return 'Минимум 3 символа';
    if (s.length > 80) return 'Максимум 80 символов';
    return null;
  }

  String? _validateDesc(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Введите описание';
    if (s.length < 10) return 'Минимум 10 символов';
    if (s.length > 800) return 'Максимум 800 символов';
    return null;
  }

  String? _validatePoints(String? v) {
    final s = (v ?? '').trim();
    final n = int.tryParse(s);
    if (n == null) return 'Введите число';
    if (n < 1) return 'Минимум 1';
    if (n > 100000) return 'Слишком много';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(tasksRepositoryProvider);
      final points = int.parse(_pointsCtrl.text.trim());

      final patch = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category.trim(),
        'pointsReward': points,
        'isActive': _isActive,
      };

      await repo.updateTask(widget.taskId, patch: patch);

      await ref.read(adminTasksListProvider.notifier).refresh();
      ref.invalidate(adminTaskByIdProvider(widget.taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
        context.pop();
      }
    } on AppError catch (e) {
      if (!mounted) return;

      if (e.code == 'NO_CHURCH') {
        context.go(AppRoutes.church);
        return;
      }

      if (e.code == 'UNAUTHORIZED') {
        context.go(AppRoutes.register);
        return;
      }

      final msg = e.code == 'FORBIDDEN'
          ? 'Нет д��ступа'
          : (e.message.isNotEmpty ? e.message : 'Ошибка');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const NoAccessScreen();

    final async = ref.watch(adminTaskByIdProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать задание')),
      body: async.when(
        data: (task) {
          if (!_loadedOnce) {
            _loadedOnce = true;
            _fill(task);
          }

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _isActive = v),
                    title: const Text('Активно'),
                    subtitle: const Text('Выключенное задание не показывается пользователям'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateTitle,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateDesc,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'GENERAL', child: Text('GENERAL')),
                      DropdownMenuItem(value: 'PRAYER', child: Text('PRAYER')),
                      DropdownMenuItem(value: 'SERVICE', child: Text('SERVICE')),
                      DropdownMenuItem(value: 'BIBLE', child: Text('BIBLE')),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _category = v ?? 'GENERAL'),
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pointsCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Очки',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePoints,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) {
          final appErr = err is AppError ? err : null;
          if (appErr != null) {
            if (appErr.code == 'NO_CHURCH') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.church);
              });
            }
            if (appErr.code == 'UNAUTHORIZED') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.register);
              });
            }
            if (appErr.code == 'FORBIDDEN') {
              return _ForbiddenState(onBack: () => context.pop());
            }
          }

          final msg = appErr?.message ?? err.toString();
          return _ErrorState(
            message: msg.isNotEmpty ? msg : 'Не удалось загрузить задание',
            onRetry: () => ref.invalidate(adminTaskByIdProvider(widget.taskId)),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForbiddenState extends StatelessWidget {
  const _ForbiddenState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Нет доступа',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'У твоего аккаунта нет прав для редактирования задания.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}
