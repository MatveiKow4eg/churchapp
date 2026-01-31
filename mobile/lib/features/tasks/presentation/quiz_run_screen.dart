import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/task_model.dart';
import '../tasks_providers.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/user_session_provider.dart';

class QuizRunScreen extends ConsumerStatefulWidget {
  const QuizRunScreen({super.key, required this.task, required this.attemptId});

  final TaskModel task;
  final String attemptId;

  @override
  ConsumerState<QuizRunScreen> createState() => _QuizRunScreenState();
}

class _QuizRunScreenState extends ConsumerState<QuizRunScreen> {
  // questionId -> selected option IDs
  final Map<String, Set<String>> _selected = <String, Set<String>>{};
  bool _submitting = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final quiz = widget.task.quiz;
    if (quiz != null) {
      for (final q in quiz.questions) {
        _selected[q.id] = <String>{};
      }
    }
  }

  void _goNext() {
    final quiz = widget.task.quiz;
    if (quiz == null) return;
    if (_currentIndex < quiz.questions.length - 1) {
      setState(() => _currentIndex += 1);
    }
  }

  void _toggleSingle(String questionId, String optionId) {
    final set = _selected[questionId] ?? <String>{};
    set
      ..clear()
      ..add(optionId);
    setState(() => _selected[questionId] = set);

    // Автопереход к следующему вопросу (если не последний)
    final quiz = widget.task.quiz;
    if (quiz != null && _currentIndex < quiz.questions.length - 1) {
      setState(() => _currentIndex += 1);
    }
  }

  void _toggleMulti(String questionId, String optionId, bool newValue) {
    final set = _selected[questionId] ?? <String>{};
    if (newValue) {
      set.add(optionId);
    } else {
      set.remove(optionId);
    }
    setState(() => _selected[questionId] = set);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);

    final quiz = widget.task.quiz;
    if (quiz == null || quiz.questions.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Нет вопросов для отправки')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      final answers = quiz.questions.map((q) {
        final sel = _selected[q.id] ?? <String>{};
        return {
          'questionId': q.id,
          'selectedOptionIds': sel.toList(growable: false),
        };
      }).toList(growable: false);

      final result = await repo.submitQuizAttempt(widget.task.id, widget.attemptId, answers);
      final score = (result['scorePercent'] is num)
          ? (result['scorePercent'] as num).toInt()
          : int.tryParse('${result['scorePercent']}') ?? 0;
      final isPassed = result['isPassed'] == true;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Результат'),
          content: Text(isPassed
              ? 'Поздравляем! Тест пройден.\nРезультат: $score%'
              : 'Тест не пройден.\nРезультат: $score%'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (isPassed) {
        // Уходим к списку заданий
        context.go(AppRoutes.tasks);
      } else {
        // Возвращаемся к деталям задания
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.task.quiz;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Викторина'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: (quiz == null || quiz.questions.isEmpty)
          ? const Center(child: Text('Нет вопросов'))
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                                                        if (quiz.maxAttempts != null)
                              _Badge(
                                text: 'Попыток: ${quiz.maxAttempts}',
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Прогресс прохождения
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: LinearProgressIndicator(
                      value: quiz.questions.isEmpty
                          ? 0
                          : (_currentIndex + 1) / quiz.questions.length,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Один вопрос за раз
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Builder(
                        builder: (context) {
                          final q = quiz.questions[_currentIndex];
                          final selected = _selected[q.id] ?? <String>{};
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Вопрос ${_currentIndex + 1} из ${quiz.questions.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    q.text,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  // Варианты
                                  Expanded(
                                    child: ListView(
                                      children: q.options.map((opt) {
                                        if (q.multiSelect) {
                                          final isChecked = selected.contains(opt.id);
                                          return CheckboxListTile(
                                            value: isChecked,
                                            onChanged: (v) => _toggleMulti(q.id, opt.id, v ?? false),
                                            controlAffinity: ListTileControlAffinity.leading,
                                            title: Text(opt.text),
                                          );
                                        } else {
                                          return RadioListTile<String>(
                                            value: opt.id,
                                            groupValue: selected.isNotEmpty ? selected.first : null,
                                            onChanged: (_) => _toggleSingle(q.id, opt.id),
                                            title: Text(opt.text),
                                          );
                                        }
                                      }).toList(growable: false),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Только вперёд или сдача на последнем вопросе
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          if (_currentIndex < quiz.questions.length - 1)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _goNext,
                                icon: const Icon(Icons.chevron_right),
                                label: const Text('Далее'),
                              ),
                            )
                          else
                            Expanded(
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Сдать'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}
