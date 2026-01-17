import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bible_annotations_providers.dart';
import '../bible_annotations_storage.dart';
import '../bible_providers.dart';

class BibleNotesScreen extends ConsumerWidget {
  const BibleNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bibleAnnotationsProvider);

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
        title: const Text('Заметки'),
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
                return (refVerse, e.value);
              })
              .toList()
            ..sort((a, b) {
              // Sort by updatedAt desc, fallback by ref.
              final ad = a.$2.updatedAt;
              final bd = b.$2.updatedAt;
              if (ad != null && bd != null) {
                final c = bd.compareTo(ad);
                if (c != 0) return c;
              }
              final ar = a.$1;
              final br = b.$1;
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
                  final (vr, ann) = items[index];
                  final bookName = byId[vr.bookId]?.name ?? vr.bookId;
                  final title = '$bookName ${vr.chapter}:${vr.verse}';
                  final note = (ann.note ?? '').trim();

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.go(
                        '/bible/${vr.bookId}/${vr.chapter}',
                        extra: {
                          'bookName': bookName,
                          'highlightVerse': vr.verse,
                          'highlightToVerse': vr.verse,
                        },
                      );
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
