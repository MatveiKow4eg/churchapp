import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bible_providers.dart';
import '../bible_progress_providers.dart';
import '../models/book.dart';

enum _BooksFilter { all, gospels, psalms, ot }

class BibleBooksScreen extends ConsumerStatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  ConsumerState<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends ConsumerState<BibleBooksScreen> {
  _BooksFilter _filter = _BooksFilter.all;

  static const Set<String> _gospelIds = {'MAT', 'MRK', 'LUK', 'JHN'};
  static const Set<String> _psalmsIds = {'PSA', 'PS'};

  static const Set<String> _ntIds = {
    'MAT','MRK','LUK','JHN','ACT','ROM','1CO','2CO','GAL','EPH','PHP','COL',
    '1TH','2TH','1TI','2TI','TIT','PHM','HEB','JAS','1PE','2PE','1JN','2JN','3JN','JUD','REV'
  };

  List<Book> _applyFilter(List<Book> books) {
    switch (_filter) {
      case _BooksFilter.all:
        return books;
      case _BooksFilter.gospels:
        return books.where((b) => _gospelIds.contains(b.id)).toList();
      case _BooksFilter.psalms:
        return books.where((b) => _psalmsIds.contains(b.id)).toList();
      case _BooksFilter.ot:
        return books.where((b) => !_ntIds.contains(b.id)).toList();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<_BooksFilter>(
                value: _BooksFilter.all,
                groupValue: _filter,
                title: const Text('Все'),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<_BooksFilter>(
                value: _BooksFilter.gospels,
                groupValue: _filter,
                title: const Text('Евангелия'),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<_BooksFilter>(
                value: _BooksFilter.psalms,
                groupValue: _filter,
                title: const Text('Псалмы'),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<_BooksFilter>(
                value: _BooksFilter.ot,
                groupValue: _filter,
                title: const Text('Ветхий Завет'),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Used to force FutureBuilder re-run without setState-heavy logic.
  int _reloadKey = 0;

  void _openChapter(BuildContext context, Book book, int chapter) {
    context.go(
      '/bible/${book.id}/$chapter',
      extra: {
        'bookName': book.name,
        'maxChapters': book.chaptersCount,
      },
    );
  }

  void _showChaptersSheet(BuildContext context, Book book) {
    final max = book.chaptersCount;
    if (max == null || max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить количество глав')),
      );
      _openChapter(context, book, 1);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Выберите главу',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: max,
                    itemBuilder: (context, index) {
                      final chapterNumber = index + 1;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          _openChapter(this.context, book, chapterNumber);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chapterNumber.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bibleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If Bible was opened as a tab (no back stack), fall back to Tasks.
              context.go('/tasks');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Библия (SYN)'),
        actions: [
          IconButton(
            tooltip: 'Фильтр',
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            tooltip: 'Поиск',
            icon: const Icon(Icons.search),
            onPressed: () {
              context.go('/bible/search');
            },
          ),
        ],
      ),
      body: FutureBuilder(
        key: ValueKey(_reloadKey),
        future: repo.getRusSynBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _reloadKey++),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          final books = snapshot.data ?? const [];
          final visibleBooks = _applyFilter(books);

          final lastPosAsync = ref.watch(lastBiblePositionProvider);
          final lastPos = lastPosAsync.valueOrNull;

          return ListView.separated(
            itemCount: visibleBooks.length + (lastPos == null ? 0 : 1),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (lastPos != null && index == 0) {
                // Prefer full book name from the loaded books list to avoid codes like GEN/EXO.
                final booksList = snapshot.data ?? const [];
                final byId = {for (final b in booksList) b.id: b};
                final title = lastPos.bookName ?? byId[lastPos.bookId]?.name ?? lastPos.bookId;
                return Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: ListTile(
                    title: const Text('Продолжить чтение'),
                    subtitle: Text('$title ${lastPos.chapter}'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      context.go(
                        '/bible/${lastPos.bookId}/${lastPos.chapter}',
                        extra: {
                          'bookName': lastPos.bookName,
                        },
                      );
                    },
                  ),
                );
              }

              final bookIndex = index - (lastPos == null ? 0 : 1);
              final book = visibleBooks[bookIndex];

              return ListTile(
                title: Text(book.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showChaptersSheet(context, book);
                },
              );
            },
          );
        },
      ),
    );
  }
}
