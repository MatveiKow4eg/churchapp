import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';

import '../bible_annotations_providers.dart';
import '../bible_annotations_storage.dart';
import '../bible_providers.dart';

class BibleNotesScreen extends ConsumerStatefulWidget {
  const BibleNotesScreen({super.key});

  @override
  ConsumerState<BibleNotesScreen> createState() => _BibleNotesScreenState();
}

class _BibleNotesScreenState extends ConsumerState<BibleNotesScreen> {
  final Set<String> _selectedKeys = <String>{};
  bool _syncScheduled = false;

  bool get _selectionMode => _selectedKeys.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // When opening the screen, trigger a best-effort refresh from the backend.
    // Do it only once per screen instance to avoid spamming on rebuilds.
    if (!_syncScheduled) {
      _syncScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref.read(bibleAnnotationsProvider.notifier).syncAllFromServerBestEffort();
      });
    }

    final async = ref.watch(bibleAnnotationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Отменить выделение',
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selectedKeys.clear),
              )
            : IconButton(
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
        title: Text(_selectionMode ? 'Выбрано: ${_selectedKeys.length}' : 'Заметки'),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final notifier = ref.read(bibleAnnotationsProvider.notifier);

                // Clear notes for selected verses.
                final refs = _selectedKeys
                    .map((k) => BibleVerseRef.fromKey(k))
                    .toList(growable: false);

                await notifier.clearForVerses(refs);

                if (mounted) {
                  setState(_selectedKeys.clear);
                }
              },
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          final repo = ref.watch(bibleRepositoryProvider);

          final items = data.byVerseKey.entries
              .where((e) => (e.value.note ?? '').trim().isNotEmpty)
              .map((e) {
                final refVerse = BibleVerseRef.fromKey(e.key);
                return (e.key, refVerse, e.value);
              })
              .toList()
            ..sort((a, b) {
              // Sort by updatedAt desc, fallback by ref.
              final ad = a.$3.updatedAt;
              final bd = b.$3.updatedAt;
              if (ad != null && bd != null) {
                final c = bd.compareTo(ad);
                if (c != 0) return c;
              }
              final ar = a.$2;
              final br = b.$2;
              final c1 = ar.bookId.compareTo(br.bookId);
              if (c1 != 0) return c1;
              final c2 = ar.chapter.compareTo(br.chapter);
              if (c2 != 0) return c2;
              return ar.verse.compareTo(br.verse);
            });

          if (items.isEmpty) {
            return const Center(child: Text('Пока нет заметок'));
          }

          return FutureBuilder(
            future: repo.getRusSynBooks(),
            builder: (context, snapshot) {
              final books = snapshot.data ?? const [];
              final byId = {for (final b in books) b.id: b};

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final (key, vr, ann) = items[index];
                  final bookName = byId[vr.bookId]?.name ?? vr.bookId;
                  final title = '$bookName ${vr.chapter}:${vr.verse}';
                  final note = (ann.note ?? '').trim();
                  final selected = _selectedKeys.contains(key);

                  return ListTile(
                    selected: selected,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                    title: Text(title),
                    subtitle: Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: _selectionMode
                        ? (selected
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.radio_button_unchecked))
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      if (_selectionMode) {
                        setState(() {
                          if (selected) {
                            _selectedKeys.remove(key);
                          } else {
                            _selectedKeys.add(key);
                          }
                        });
                        return;
                      }

                      context.go(
                        '/bible/${vr.bookId}/${vr.chapter}',
                        extra: {
                          'bookName': bookName,
                          'highlightVerse': vr.verse,
                          'highlightToVerse': vr.verse,
                        },
                      );
                    },
                    onLongPress: () {
                      setState(() {
                        if (selected) {
                          _selectedKeys.remove(key);
                        } else {
                          _selectedKeys.add(key);
                        }
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
