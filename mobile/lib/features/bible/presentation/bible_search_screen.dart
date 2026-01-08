import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bible_providers.dart';
import '../models/bible_search.dart';
import '../models/book.dart';

class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({
    super.key,
    this.initialBookId,
    this.initialBookName,
  });

  final String? initialBookId;
  final String? initialBookName;

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  Timer? _debounce;

  bool _loadingBooks = false;
  List<Book> _books = const [];
  Book? _selectedBook;

  String? _bookId;
  String? _bookName;
  int? _maxChapters;

  bool _loading = false;
  String? _error;
  BibleSearchResponse? _response;

  @override
  void initState() {
    super.initState();

    _bookId = widget.initialBookId?.trim().isEmpty == true
        ? null
        : widget.initialBookId?.trim();
    _bookName = widget.initialBookName?.trim().isEmpty == true
        ? null
        : widget.initialBookName?.trim();

    if (_bookId == null) {
      _loadBooks();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loadingBooks = true;
      _error = null;
    });

    try {
      final repo = ref.read(bibleRepositoryProvider);
      final books = await repo.getRusSynBooks();

      if (!mounted) return;

      Book? initialSelected;
      if (_bookId != null) {
        try {
          initialSelected = books.firstWhere((b) => b.id == _bookId);
        } catch (_) {
          initialSelected = null;
        }
      }

      setState(() {
        _books = books;
        _selectedBook = initialSelected;
        _loadingBooks = false;

        if (initialSelected != null) {
          _bookId = initialSelected.id;
          _bookName = initialSelected.name;
          _maxChapters = initialSelected.chaptersCount;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBooks = false;
      });
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search();
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _queryController.clear();
    setState(() {
      _error = null;
      _response = null;
    });
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    final bookId = _bookId;

    if (query.length < 2 || bookId == null || bookId.isEmpty) {
      setState(() {
        _loading = false;
        _response = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bibleRepositoryProvider);
      final resp = await repo.searchRusSynInBook(
        bookId: bookId,
        query: query,
        limit: 50,
      );

      if (!mounted) return;
      setState(() {
        _response = resp;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _response = null;
      });
    }
  }

  List<TextSpan> _buildHighlightedSnippet(
    BuildContext context, {
    required String text,
    required String query,
  }) {
    final q = query.trim();
    if (q.isEmpty) return [TextSpan(text: text)];

    final reg = RegExp(RegExp.escape(q), caseSensitive: false);
    final matches = reg.allMatches(text).toList();
    if (matches.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    var last = 0;

    for (final m in matches) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }

      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim();
    final bookId = _bookId;

    final results = _response?.results ?? const <BibleSearchHit>[];

    final canSearch = (bookId != null && bookId.isNotEmpty) && query.length >= 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/bible');
            }
          },
        ),
        title: const Text('Поиск'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                if (widget.initialBookId == null)
                  Column(
                    children: [
                      if (_loadingBooks)
                        const LinearProgressIndicator(minHeight: 2)
                      else
                        DropdownButtonFormField<Book>(
                          value: _selectedBook,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Книга',
                            border: OutlineInputBorder(),
                          ),
                          items: _books
                              .map(
                                (b) => DropdownMenuItem<Book>(
                                  value: b,
                                  child: Text(b.name),
                                ),
                              )
                              .toList(),
                          onChanged: (b) {
                            setState(() {
                              _selectedBook = b;
                              _bookId = b?.id;
                              _bookName = b?.name;
                              _maxChapters = b?.chaptersCount;
                              _response = null;
                              _error = null;
                            });
                            _scheduleSearch();
                          },
                        ),
                      const SizedBox(height: 10),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _bookName ?? _bookId ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                TextField(
                  controller: _queryController,
                  focusNode: _queryFocus,
                  decoration: InputDecoration(
                    labelText: 'Запрос (минимум 2 символа)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить',
                            icon: const Icon(Icons.clear),
                            onPressed: _clearQuery,
                          ),
                  ),
                  onChanged: (_) {
                    setState(() {
                      _error = null;
                    });
                    _scheduleSearch();
                  },
                  onSubmitted: (_) => _search(),
                ),
                if (!canSearch)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Выберите книгу и введите минимум 2 символа'),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = results[index];

                      final title = (r.ref != null && r.ref!.trim().isNotEmpty)
                          ? r.ref!.trim()
                          : '${_bookName ?? _bookId ?? ''} ${r.chapter}:${r.verse}';

                      return ListTile(
                        title: Text(title),
                        subtitle: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: _buildHighlightedSnippet(
                              context,
                              text: r.text,
                              query: query,
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final bId = _bookId;
                          if (bId == null || bId.isEmpty) return;

                          context.go(
                            '/bible/$bId/${r.chapter}',
                            extra: {
                              'bookName': _bookName ?? bId,
                              'maxChapters': _maxChapters,
                              'highlightVerse': r.verse,
                              'highlightQuery': query,
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
