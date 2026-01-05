import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';
import '../../tasks/tasks_providers.dart';
import '../presentation/no_access_screen.dart';
import 'admin_tasks_providers.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');

  String _category = 'OTHER';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
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
    if (s.length > 2000) return 'Максимум 2000 символов';
    return null;
  }

  String? _validatePoints(String? v) {
    final s = (v ?? '').trim();
    final n = int.tryParse(s);
    if (n == null) return 'Введите число';
    if (n < 1) return 'Минимум 1';
    if (n > 10000) return 'Максимум 10000';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(tasksRepositoryProvider);
      final points = int.parse(_pointsCtrl.text.trim());

      await repo.createTask(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _category,
        pointsReward: points,
      );

      // Refresh list
      await ref.read(adminTasksListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задание создано')),
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
          ? 'Нет доступа'
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

    return Scaffold(
      appBar: AppBar(title: const Text('Создать задание')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                  DropdownMenuItem(value: 'SPIRITUAL', child: Text('SPIRITUAL')),
                  DropdownMenuItem(value: 'SERVICE', child: Text('SERVICE')),
                  DropdownMenuItem(value: 'COMMUNITY', child: Text('COMMUNITY')),
                  DropdownMenuItem(value: 'CREATIVITY', child: Text('CREATIVITY')),
                  DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _category = v ?? 'OTHER'),
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
      ),
    );
  }
}
