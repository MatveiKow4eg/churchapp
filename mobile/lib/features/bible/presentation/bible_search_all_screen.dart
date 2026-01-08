import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bible_providers.dart';
import '../models/bible_search.dart';

class BibleSearchAllScreen extends ConsumerStatefulWidget {
  const BibleSearchAllScreen({
    super.key,
    required this.query,
    required this.initialResults,
  });

  final String query;
  final List<BibleSearchHit> initialResults;

  @override
  ConsumerState<BibleSearchAllScreen> createState() => _BibleSearchAllScreenState();
}

class _BibleSearchAllScreenState extends ConsumerState<BibleSearchAllScreen> {
  final List<BibleSearchHit> _items = [];
  bool _loading = false;
  bool _reachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.initialResults);
    // kick off loading the rest
    Future.microtask(_loadMore);
  }

  Future<void> _loadMore() async {
    if (_loading || _reachedEnd) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bibleRepositoryProvider);
      final offset = _items.length;
      const limit = 200;

      final resp = await repo.searchAllBible(
        widget.query,
        limit: limit,
        offset: offset,
        timeBudgetMs: 15000,
      );

      final arrived = resp.results;

      // dedup by ref or compound key
      final existing = <String>{
        for (final h in _items)
          (h.ref != null && h.ref!.isNotEmpty)
              ? h.ref!
              : '${h.bookId}:${h.chapter}:${h.verse}'
      };

      final toAdd = <BibleSearchHit>[];
      for (final h in arrived) {
        final key = (h.ref != null && h.ref!.isNotEmpty)
            ? h.ref!
            : '${h.bookId}:${h.chapter}:${h.verse}';
        if (existing.add(key)) {
          toAdd.add(h);
        }
      }

      setState(() {
        _items.addAll(toAdd);
        _loading = false;
        if (arrived.length < limit) {
          _reachedEnd = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Поиск: "${widget.query}"'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final hit = _items[index];
                      final title = '${hit.bookName ?? hit.bookId} ${hit.chapter}:${hit.verse}';

                      return ListTile(
                        title: Text(title),
                        subtitle: Text(
                          hit.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          context.go(
                            '/bible/${hit.bookId}/${hit.chapter}',
                            extra: {
                              'bookName': hit.bookName ?? hit.bookId,
                              'highlightVerse': hit.verse,
                              'highlightQuery': widget.query,
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                if (_loading) const CircularProgressIndicator(),
                if (!_loading && !_reachedEnd)
                  FilledButton(
                    onPressed: _loadMore,
                    child: const Text('Загрузить ещё'),
                  ),
                if (!_loading && _reachedEnd)
                  const Text('Конец результатов'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
