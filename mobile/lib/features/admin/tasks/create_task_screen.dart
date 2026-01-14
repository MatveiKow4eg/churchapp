import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/ui/bible_refs.dart';
import '../../auth/user_session_provider.dart';
import '../../bible/bible_providers.dart';
import '../../bible/models/book.dart';
import '../../tasks/tasks_providers.dart';
import '../ai/admin_ai_providers.dart';
import '../presentation/no_access_screen.dart';
import 'admin_tasks_providers.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');

  String _category = 'OTHER';
  bool _saving = false;
  bool _improving = false;
  bool _aiTitleLoading = false;
  bool _aiDescLoading = false;

  late final TabController _tabController;

  final List<_BibleRefDraft> _refs = <_BibleRefDraft>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refs.add(_BibleRefDraft.empty());
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final r in _refs) {
      r.dispose();
    }
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

  Future<void> _showTitleVariants(List<String> items) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = items[i];
              return ListTile(
                title: Text(s),
                onTap: () => Navigator.of(ctx).pop(s),
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;

    // Do NOT auto-replace without confirmation.
    if (selected != null && selected.trim().isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Подтвердить замену'),
          content: Text('Заменить название на:\n\n${selected.trim()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Заменить'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _titleCtrl.text = selected.trim();
      }
    }
  }

  Future<void> _aiSuggestTitle() async {
    final text = _titleCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст')),
      );
      return;
    }

    setState(() => _aiTitleLoading = true);

    try {
      final repo = ref.read(adminAiRepositoryProvider);
      final items = await repo.suggestTaskTitles(text: text);

      if (!mounted) return;

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось улучшить текст, попробуй ещё раз')),
        );
        return;
      }

      await _showTitleVariants(items);
    } on AppError catch (e) {
      if (!mounted) return;

      if (e.code == 'UNAUTHORIZED') {
        context.go(AppRoutes.register);
        return;
      }

      // rate limit
      if (e.code == 'RATE_LIMIT') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Слишком частые запросы. Попробуй позже')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось улучшить текст, попробуй ещё раз')),
      );
    } finally {
      if (mounted) setState(() => _aiTitleLoading = false);
    }
  }

  Future<void> _aiRewriteDescription() async {
    final original = _descCtrl.text.trim();
    if (original.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст')),
      );
      return;
    }

    setState(() => _aiDescLoading = true);

    try {
      final repo = ref.read(adminAiRepositoryProvider);
      final improved = await repo.rewriteTaskDescription(text: original);

      if (!mounted) return;

      final apply = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Сравнение'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Оригинал', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(original),
                    const SizedBox(height: 14),
                    const Text('Улучшено', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(improved),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Применить'),
              ),
            ],
          );
        },
      );

      if (apply == true) {
        _descCtrl.text = improved;
      }
    } on AppError catch (e) {
      if (!mounted) return;

      if (e.code == 'UNAUTHORIZED') {
        context.go(AppRoutes.register);
        return;
      }

      if (e.code == 'RATE_LIMIT') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Слишком частые запросы. Попробуй позже')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось улучшить текст, попробуй ещё раз')),
      );
    } finally {
      if (mounted) setState(() => _aiDescLoading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(tasksRepositoryProvider);
      final points = int.parse(_pointsCtrl.text.trim());

      // Convert drafts to refs and attach bookName from the live books list.
      final books = await ref.read(_rusSynBooksProvider.future);
      final byId = {for (final b in books) b.id: b};

      final bibleRefs = _refs
          .map((d) => d.toBibleRef())
          .whereType<BibleRef>()
          .map((r) {
            final bookName = byId[r.bookId]?.name ?? r.bookId;
            return BibleRef(
              translationId: r.translationId,
              bookId: r.bookId,
              bookName: bookName,
              fromChapter: r.fromChapter,
              fromVerse: r.fromVerse,
              toChapter: r.toChapter,
              toVerse: r.toVerse,
            );
          })
          .toList(growable: false);

      final description = upsertBibleRefsInDescription(
        _descCtrl.text,
        bibleRefs,
      );

      await repo.createTask(
        title: _titleCtrl.text,
        description: description,
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

    final booksFuture = ref.watch(_rusSynBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать задание'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Основное'),
            Tab(text: 'Места Писания'),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    enabled: !_saving && !_aiTitleLoading && !_aiDescLoading,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'AI варианты',
                        onPressed: (_saving || _aiTitleLoading || _aiDescLoading)
                            ? null
                            : _aiSuggestTitle,
                        icon: _aiTitleLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('✨', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    validator: _validateTitle,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    enabled: !_saving && !_aiTitleLoading && !_aiDescLoading,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateDesc,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: (_saving || _aiTitleLoading || _aiDescLoading)
                        ? null
                        : _aiRewriteDescription,
                    icon: _aiDescLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('✨', style: TextStyle(fontSize: 18)),
                    label: const Text('✨ Сделать понятнее'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(
                        value: 'SPIRITUAL',
                        child: Text('Духовное'),
                      ),
                      DropdownMenuItem(
                        value: 'SERVICE',
                        child: Text('Служение / помощь'),
                      ),
                      DropdownMenuItem(
                        value: 'COMMUNITY',
                        child: Text('Сообщество / общение'),
                      ),
                      DropdownMenuItem(
                        value: 'CREATIVITY',
                        child: Text('Творчество'),
                      ),
                      DropdownMenuItem(
                        value: 'REFLECTION',
                        child: Text('Рассуждение'),
                      ),
                      DropdownMenuItem(
                        value: 'OTHER',
                        child: Text('Другое'),
                      ),
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
                    onPressed: (_saving || _aiTitleLoading || _aiDescLoading)
                        ? null
                        : _save,
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
              booksFuture.when(
                data: (books) {
                  return _BibleRefsTab(
                    enabled: !_saving,
                    books: books,
                    refs: _refs,
                    onAdd: () => setState(() => _refs.add(_BibleRefDraft.empty())),
                    onRemove: (index) {
                      setState(() {
                        final r = _refs.removeAt(index);
                        r.dispose();
                        if (_refs.isEmpty) _refs.add(_BibleRefDraft.empty());
                      });
                    },
                    onChanged: () => setState(() {}),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Не удалось загрузить список книг Библии',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => ref.invalidate(_rusSynBooksProvider),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _rusSynBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repo = ref.watch(bibleRepositoryProvider);
  return repo.getRusSynBooks();
});

class _BibleRefsTab extends StatelessWidget {
  const _BibleRefsTab({
    required this.enabled,
    required this.books,
    required this.refs,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final bool enabled;
  final List<Book> books;
  final List<_BibleRefDraft> refs;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Выбери места Писания для задания',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Пользователи смогут открыть эти места прямо из задания.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < refs.length; i++) ...[
          _BibleRefCard(
            index: i,
            enabled: enabled,
            books: books,
            draft: refs[i],
            onChanged: onChanged,
            onRemove: refs.length <= 1 ? null : () => onRemove(i),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? onAdd : null,
          icon: const Icon(Icons.add),
          label: const Text('Добавить место'),
        ),
        const SizedBox(height: 12),
        Text(
          'Совет: можно указать диапазон стихов (например 1:1–1:10) или целую главу (например 3).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _BibleRefCard extends StatelessWidget {
  const _BibleRefCard({
    required this.index,
    required this.enabled,
    required this.books,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final bool enabled;
  final List<Book> books;
  final _BibleRefDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = books.where((b) => b.id == draft.bookId).firstOrNull;
    final maxChapters = selected?.chaptersCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Место ${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: draft.bookId.isEmpty ? null : draft.bookId,
              items: books
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: enabled
                  ? (v) {
                      draft.bookId = v ?? '';
                      // Reset chapter selection when switching book.
                      draft.fromChapterCtrl.text = '';
                      draft.toChapterCtrl.text = '';
                      onChanged();
                    }
                  : null,
              decoration: const InputDecoration(
                labelText: 'Книга',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.fromChapterCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Глава от',
                      hintText: maxChapters == null ? '1' : '1–$maxChapters',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: draft.fromVerseCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Стих от (необязательно)',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.toChapterCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Глава до (необязательно)',
                      hintText: maxChapters == null ? '' : '1–$maxChapters',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: draft.toVerseCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Стих до (необязательно)',
                      hintText: '10',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (selected != null)
              Text(
                'Выбрано: ${draft.toDisplayString(selected.name)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Text(
                'Выбрано: —',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BibleRefDraft {
  _BibleRefDraft({
    required this.fromChapterCtrl,
    required this.fromVerseCtrl,
    required this.toChapterCtrl,
    required this.toVerseCtrl,
    required this.bookId,
  });

  String bookId;

  final TextEditingController fromChapterCtrl;
  final TextEditingController fromVerseCtrl;
  final TextEditingController toChapterCtrl;
  final TextEditingController toVerseCtrl;

  factory _BibleRefDraft.empty() => _BibleRefDraft(
        bookId: '',
        fromChapterCtrl: TextEditingController(),
        fromVerseCtrl: TextEditingController(),
        toChapterCtrl: TextEditingController(),
        toVerseCtrl: TextEditingController(),
      );

  void dispose() {
    fromChapterCtrl.dispose();
    fromVerseCtrl.dispose();
    toChapterCtrl.dispose();
    toVerseCtrl.dispose();
  }

  int? _intOrNull(String s) => int.tryParse(s.trim());

  BibleRef? toBibleRef() {
    if (bookId.trim().isEmpty) return null;
    final fromChapter = _intOrNull(fromChapterCtrl.text);
    if (fromChapter == null || fromChapter < 1) return null;

    final fromVerse = _intOrNull(fromVerseCtrl.text);
    final toChapter = _intOrNull(toChapterCtrl.text);
    final toVerse = _intOrNull(toVerseCtrl.text);

    // bookName is filled later based on selected book list.
    // Here we keep it empty; it will be overwritten in CreateTaskScreen where
    // we have access to the books list.
    return BibleRef(
      translationId: 'rus_syn',
      bookId: bookId.trim(),
      bookName: '',
      fromChapter: fromChapter,
      fromVerse: fromVerse,
      toChapter: toChapter,
      toVerse: toVerse,
    );
  }

  String toDisplayString(String bookName) {
    final fc = _intOrNull(fromChapterCtrl.text);
    final fv = _intOrNull(fromVerseCtrl.text);
    final tc = _intOrNull(toChapterCtrl.text);
    final tv = _intOrNull(toVerseCtrl.text);

    if (fc == null || fc < 1) return '$bookName —';

    String part(int ch, int? v) => v == null ? '$ch' : '$ch:$v';

    final from = part(fc, fv);
    final to = (tc == null && tv == null) ? null : part(tc ?? fc, tv);

    if (to == null || to == from) return '$bookName $from';
    return '$bookName $from–$to';
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
