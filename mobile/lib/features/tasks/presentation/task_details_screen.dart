import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../submissions/create_submission_controller.dart';
import '../tasks_providers.dart';
import '../../../core/ui/task_category_i18n.dart';
import '../../../core/ui/bible_refs.dart';
import '../../tasks/task_draft_providers.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _pendingLocally = false;

  /// Draft text for the submit bottom sheet.
  ///
  /// Backed by persistent storage so it survives tab switches and app restarts.
  final TextEditingController _submitCommentController =
      TextEditingController();

  bool _draftLoaded = false;

  TextEditingController? _sheetController;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskByIdProvider(widget.taskId));

    // Load draft once per screen instance.
    if (!_draftLoaded) {
      _draftLoaded = true;
      Future.microtask(() async {
        final storage = ref.read(taskDraftStorageProvider);
        final saved = await storage.loadCommentDraft(widget.taskId);
        if (!mounted) return;
        if (saved != null && saved.isNotEmpty) {
          _submitCommentController.text = saved;
        }
      });

      // Persist on each change.
      _submitCommentController.addListener(() {
        final storage = ref.read(taskDraftStorageProvider);
        storage.saveCommentDraft(widget.taskId, _submitCommentController.text);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задание'),
      ),
      body: async.when(
        data: (task) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingLocally) ...[
                    const _StatusBadge(text: 'Ожидает подтверждения'),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _Badge(
                                text: task.category.isEmpty
                                    ? 'Без категории'
                                    : localizeTaskCategory(task.category),
                              ),
                              const Spacer(),
                              Text(
                                '+${task.pointsReward} очков',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            stripBibleRefsFromDescription(task.description),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final refs =
                                  parseBibleRefsFromDescription(task.description);
                              if (refs.isEmpty) return const SizedBox.shrink();

                              return OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    builder: (sheetContext) {
                                      return SafeArea(
                                        child: ListView(
                                          padding: const EdgeInsets.all(16),
                                          shrinkWrap: true,
                                          children: [
                                            Text(
                                              'Места Писания',
                                              style: Theme.of(sheetContext)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            for (final r in refs)
                                              ..._buildBibleRefTiles(
                                                context: context,
                                                sheetContext: sheetContext,
                                                ref: r,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.menu_book_outlined),
                                label: Text(
                                  'Места Писания (${_countBibleRefItems(refs)})',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => _openSubmitSheet(
                        context,
                        taskCategory: task.category,
                      ),
                      child: const Text('Выполнено'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.submissionsMine),
                    child: const Text('Мои заявки'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) {
          // Auth / routing errors
          if (err is AppError && err.code == 'NO_CHURCH') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.church);
            });
          }

          if (err is AppError && err.code == 'UNAUTHORIZED') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.register);
            });
          }

          final msg =
              (err is AppError) ? err.message : 'Не удалось загрузить задание';

          return _ErrorState(
            message: msg.isNotEmpty ? msg : 'Не удалось загрузить задание',
            onRetry: () => ref.invalidate(taskByIdProvider(widget.taskId)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _submitCommentController.dispose();
    _sheetController?.dispose();
    _sheetController = null;
    super.dispose();
  }

  void _openSubmitSheet(BuildContext context, {required String taskCategory}) {
    // Use ScaffoldMessenger from the page context (NOT the sheet context), so we
    // can safely show snackbars after the sheet is closed.
    final rootScaffoldMessenger = ScaffoldMessenger.of(context);
    final rootRouter = GoRouter.of(context);

    // Create the controller inside the bottom-sheet builder so it can't be used
    // after being disposed if the sheet rebuilds / is dismissed.

    bool isReflectionTask(String category) {
      return category.trim().toUpperCase() == 'REFLECTION';
    }

    // Keep draft text between openings; only reset sheet-local controller.
    _sheetController?.dispose();
    _sheetController = null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        bool isSubmitting = false;

        // Helper that is safe to call even if the user already dismissed the sheet.
        void closeSheetIfOpen() {
          final nav = Navigator.of(sheetContext);
          if (nav.canPop()) nav.pop();
        }

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Controller must live for the lifetime of this bottom sheet.
            // Create it once per sheet, even if the builder rebuilds.
            // Using a simple closure-cached controller avoids re-initializing on rebuilds.
            final commentController = _submitCommentController;

            // The sheet can be dismissed by swipe/back; after that `setModalState`
            // will throw. Guard all sheet state updates.
            bool sheetActive = true;
            void safeSetSheetState(VoidCallback fn) {
              if (!sheetActive) return;
              setModalState(fn);
            }

            Future<void> doSubmit() async {
              if (isSubmitting) return;

              final comment = commentController.text.trim();
              if (isReflectionTask(taskCategory)) {
                if (comment.length < 20) {
                  rootScaffoldMessenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Для задания “Размышление” нужно минимум 20 символов'),
                      ),
                    );
                  return;
                }
              }

              safeSetSheetState(() => isSubmitting = true);

              try {
                await ref
                    .read(createSubmissionControllerProvider.notifier)
                    .submit(
                      taskId: widget.taskId,
                      commentUser: comment,
                    );

                // 1) Close the sheet first (using its context).
                closeSheetIfOpen();

                // Clear draft only after successful submission.
                _submitCommentController.clear();
                await ref
                    .read(taskDraftStorageProvider)
                    .clearCommentDraft(widget.taskId);

                // 2) Update parent page state (only if still mounted).
                if (!mounted) return;
                setState(() => _pendingLocally = true);

                // 3) Show snackbar via the parent ScaffoldMessenger that we
                // captured before opening the sheet.
                rootScaffoldMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Отправлено на проверку')),
                  );

                // 4) Navigate back to tasks list.
                if (!mounted) return;
                context.go(AppRoutes.tasks);
              } on AppError catch (e) {
                // If the sheet was dismissed while the request was in-flight,
                // don't try to update its state.
                safeSetSheetState(() => isSubmitting = false);

                if (e.code == 'NO_CHURCH') {
                  closeSheetIfOpen();
                  if (!mounted) return;
                  rootRouter.go(AppRoutes.church);
                  return;
                }

                if (e.code == 'UNAUTHORIZED') {
                  closeSheetIfOpen();
                  if (!mounted) return;
                  rootRouter.go(AppRoutes.register);
                  return;
                }

                rootScaffoldMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(e.message)));
              } catch (e) {
                safeSetSheetState(() => isSubmitting = false);

                rootScaffoldMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }

            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                // When the user dismisses the sheet manually, mark it inactive so
                // async callbacks won't call setModalState.
                if (didPop) sheetActive = false;
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isReflectionTask(taskCategory)
                          ? 'Ответ (минимум 20 символов)'
                          : 'Комментарий (необязательно)',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLength: isReflectionTask(taskCategory) ? 5000 : 300,
                      maxLines: isReflectionTask(taskCategory) ? 10 : 4,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: isReflectionTask(taskCategory)
                            ? 'Напиши свои мысли по заданию'
                            : 'Например: что именно сделал(а) и когда',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : doSubmit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Отправить на проверку'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Do NOT dispose the draft controller here; it must persist until submit.
      _sheetController?.dispose();
      _sheetController = null;
    });
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}


int _countBibleRefItems(List<BibleRef> refs) {
  int count = 0;
  for (final r in refs) {
    final fromCh = r.fromChapter;
    final toCh = r.toChapter ?? r.fromChapter;
    final startCh = fromCh < toCh ? fromCh : toCh;
    final endCh = fromCh < toCh ? toCh : fromCh;
    count += (endCh - startCh + 1);
  }
  return count;
}

List<Widget> _buildBibleRefTiles({
  required BuildContext context,
  required BuildContext sheetContext,
  required BibleRef ref,
}) {
  // If reference spans multiple chapters, split into per-chapter items so the
  // UI and actual highlighting match.
  final fromCh = ref.fromChapter;
  final toCh = ref.toChapter ?? ref.fromChapter;

  final startCh = fromCh < toCh ? fromCh : toCh;
  final endCh = fromCh < toCh ? toCh : fromCh;

  void go({
    required int chapter,
    int? fromVerse,
    int? toVerse,
  }) {
    Navigator.of(sheetContext).pop();
    context.push(
      '/bible/${ref.bookId}/$chapter',
      extra: {
        'bookName': ref.bookName,
        if (fromVerse != null) 'highlightVerse': fromVerse,
        if (toVerse != null) 'highlightToVerse': toVerse,
      },
    );
  }

  // Single chapter ref.
  if (startCh == endCh) {
    final fromV = ref.fromVerse;
    final toV = ref.toVerse;
    return [
      ListTile(
        title: Text(ref.toDisplayString()),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (fromV != null) {
            go(
              chapter: ref.fromChapter,
              fromVerse: fromV,
              toVerse: toV ?? fromV,
            );
          } else {
            go(chapter: ref.fromChapter);
          }
        },
      ),
    ];
  }

  // Multi-chapter ref.
  final tiles = <Widget>[];
  for (var ch = startCh; ch <= endCh; ch++) {
    final isFirst = ch == startCh;
    final isLast = ch == endCh;

    // Start verse for the first chapter: use fromVerse or 1.
    final fromV = isFirst ? (ref.fromVerse ?? 1) : 1;

    // End verse for the last chapter: use toVerse; if absent, don't pass end
    // (we can't know the last verse without fetching the chapter here).
    final toV = isLast ? ref.toVerse : null;

    final label = isFirst
        ? '${ref.bookName} $ch:${fromV}${isLast && toV != null ? '–$toV' : ''}'
        : (isLast && toV != null)
            ? '${ref.bookName} $ch:1–$toV'
            : '${ref.bookName} $ch';

    tiles.add(
      ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (isFirst && !isLast) {
            // Highlight from start verse to end of chapter (no end provided).
            go(chapter: ch, fromVerse: fromV);
          } else if (isLast && toV != null) {
            go(chapter: ch, fromVerse: fromV, toVerse: toV);
          } else {
            go(chapter: ch);
          }
        },
      ),
    );
  }

  return tiles;
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
