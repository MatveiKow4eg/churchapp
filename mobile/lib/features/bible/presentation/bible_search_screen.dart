import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';

import '../bible_providers.dart';
import '../models/bible_search.dart';

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
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  BibleSearchResponse? _resp;

  DateTime? _lastRequestAt;
  int? _activeRequestId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    final q = raw.trim();

    // Clear results on too-short query.
    if (q.length < 2) {
      _debounce?.cancel();
      final requestId = DateTime.now().microsecondsSinceEpoch;
      _activeRequestId = requestId;

      setState(() {
        _loading = false;
        _error = null;
        _resp = null;
        _lastRequestAt = DateTime.now();
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPreview(q);
    });
  }

  Future<void> _fetchPreview(String q) async {
    final requestId = DateTime.now().microsecondsSinceEpoch;
    _activeRequestId = requestId;

    setState(() {
      _loading = true;
      _error = null;
      _lastRequestAt = DateTime.now();
    });

    try {
      final repo = ref.read(bibleRepositoryProvider);
      final fetch = repo.searchRusSynPreview(
        query: q,
        limit: 4,
        timeBudgetMs: 2500,
      );
      final minDelay = Future.delayed(const Duration(seconds: 2));

      final results = await Future.wait([fetch, minDelay]);
      final resp = results.first as BibleSearchResponse;

      if (!mounted) return;
      if (_activeRequestId != requestId) return;

      setState(() {
        _resp = resp;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_activeRequestId != requestId) return;

      setState(() {
        _error = e.toString();
        _loading = false;
        _resp = null;
      });
    }
  }

  void _retry() {
    final q = _controller.text.trim();
    if (q.length < 2) return;
    _debounce?.cancel();
    _fetchPreview(q);
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
    final query = _controller.text.trim();
    final results = _resp?.results ?? const <BibleSearchHit>[];
    final canShowAll = _resp != null && query.length >= 2;

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
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Поиск по всей Библии…',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _debounce?.cancel();
                              _controller.clear();
                              final requestId = DateTime.now().microsecondsSinceEpoch;
                              _activeRequestId = requestId;
                              setState(() {
                                _loading = false;
                                _error = null;
                                _resp = null;
                                _lastRequestAt = DateTime.now();
                              });
                            },
                          ),
                  ),
                  onChanged: _onQueryChanged,
                ),
                if (canShowAll)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final current = _resp;
                        if (current == null) return;
                        context.go(
                          AppRoutes.bibleSearchAll,
                          extra: {
                            'query': query,
                            'initialResults': current.results,
                          },
                        );
                      },
                      child: const Text('Показать все'),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Ищем…'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _retry,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _resp != null
                        ? (results.isEmpty
                            ? const Center(child: Text('Ничего не найдено'))
                            : ListView.separated(
                                itemCount: results.length > 4 ? 4 : results.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final hit = results[index];
                                  final title =
                                      '${hit.bookName ?? hit.bookId} ${hit.chapter}:${hit.verse}';

                                  return ListTile(
                                    title: Text(title),
                                    subtitle: Text(
                                      hit.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      final bookId = hit.bookId;
                                      if (bookId.isEmpty) return;
                                      context.go(
                                        '/bible/$bookId/${hit.chapter}',
                                        extra: {
                                          'bookName': hit.bookName ?? bookId,
                                          'highlightVerse': hit.verse,
                                          'highlightQuery': query,
                                        },
                                      );
                                    },
                                  );
                                },
                              ))
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
