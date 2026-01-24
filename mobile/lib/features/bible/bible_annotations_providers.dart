import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'bible_annotations_repository.dart';
import 'bible_annotations_storage.dart';
import 'bible_progress_providers.dart' show flutterSecureStorageProvider;

final bibleAnnotationsStorageProvider = Provider<BibleAnnotationsStorage>((ref) {
  return BibleAnnotationsStorage(ref.watch(flutterSecureStorageProvider));
});

final bibleAnnotationsRepositoryProvider = Provider<BibleAnnotationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BibleAnnotationsRepository(apiClient: apiClient);
});

class BibleAnnotationsNotifier extends AsyncNotifier<BibleAnnotations> {
  @override
  Future<BibleAnnotations> build() async {
    // Offline-first cache.
    final local = await ref.watch(bibleAnnotationsStorageProvider).load();

    // Best-effort: after app restart, pull server annotations for all verses we
    // already know about locally. This ensures Favorites/Notes survive even if
    // secure storage was cleared, user switched device, or local cache is stale.
    //
    // We keep it silent: local cache is shown immediately, then updated.
    _syncKnownChaptersFromServer(local);

    return local;
  }

  Future<void> syncAllFromServerBestEffort() async {
    final repo = ref.read(bibleAnnotationsRepositoryProvider);

    try {
      final rows = await repo.listAll();

      // Replace local cache with server snapshot.
      var next = const BibleAnnotations();

      for (final r in rows) {
        final verseRef = BibleVerseRef(
          translationId: r.translationId,
          bookId: r.bookId,
          chapter: r.chapter,
          verse: r.verse,
        );

        BibleHighlightColor? color;
        final h = (r.highlight ?? '').trim();
        if (h.isNotEmpty) {
          color = BibleHighlightColor.values
              .where((e) => e.name == h)
              .cast<BibleHighlightColor?>()
              .firstWhere((e) => e != null, orElse: () => null);
        }

        next = next.copyWithVerse(
          verseRef,
          BibleVerseAnnotation(
            highlight: color,
            isFavorite: r.isFavorite == true,
            note: r.note,
            updatedAt: null,
          ),
        );
      }

      await _persist(next);
    } catch (_) {
      // Ignore; offline-first.
    }
  }

  @Deprecated('Use syncAllFromServerBestEffort() for Favorites/Notes screens')
  Future<void> syncKnownFromServerBestEffort() async {
    final current = state.value ?? const BibleAnnotations();
    final groups = <String, Set<int>>{}; // key = translationId:bookId, values = chapters

    for (final key in current.byVerseKey.keys) {
      try {
        final refVerse = BibleVerseRef.fromKey(key);
        final groupKey = '${refVerse.translationId}:${refVerse.bookId}';
        (groups[groupKey] ??= <int>{}).add(refVerse.chapter);
      } catch (_) {
        // ignore malformed keys
      }
    }

    for (final entry in groups.entries) {
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;
      final translationId = parts[0];
      final bookId = parts[1];

      for (final chapter in entry.value) {
        try {
          await syncFromServerChapter(
            translationId: translationId,
            bookId: bookId,
            chapter: chapter,
          );
        } catch (_) {
          // Ignore; offline-first.
        }
      }
    }
  }

  void _syncKnownChaptersFromServer(BibleAnnotations local) {
    final groups = <String, Set<int>>{}; // key = translationId:bookId, values = chapters

    for (final key in local.byVerseKey.keys) {
      try {
        final refVerse = BibleVerseRef.fromKey(key);
        final groupKey = '${refVerse.translationId}:${refVerse.bookId}';
        (groups[groupKey] ??= <int>{}).add(refVerse.chapter);
      } catch (_) {
        // ignore malformed keys
      }
    }

    if (groups.isEmpty) return;

    // Run asynchronously to avoid doing network work during provider build.
    Future.microtask(() async {
      for (final entry in groups.entries) {
        final parts = entry.key.split(':');
        if (parts.length != 2) continue;
        final translationId = parts[0];
        final bookId = parts[1];

        for (final chapter in entry.value) {
          try {
            await syncFromServerChapter(
              translationId: translationId,
              bookId: bookId,
              chapter: chapter,
            );
          } catch (_) {
            // Ignore; offline-first.
          }
        }
      }
    });
  }

  Future<void> _persist(BibleAnnotations next) async {
    state = AsyncData(next);
    await ref.read(bibleAnnotationsStorageProvider).save(next);
  }

  Future<void> _pushToServer(Iterable<BibleVerseRef> refs) async {
    if (refs.isEmpty) return;

    final current = state.value ?? const BibleAnnotations();
    final repo = ref.read(bibleAnnotationsRepositoryProvider);

    final items = refs
        .map((r) {
          final ann = current.annotationFor(r);
          return BibleAnnotationDto(
            translationId: r.translationId,
            bookId: r.bookId,
            chapter: r.chapter,
            verse: r.verse,
            highlight: BibleAnnotationDto.normalizeHighlight(ann.highlight),
            isFavorite: ann.isFavorite,
            note: (ann.note ?? '').trim().isEmpty ? null : ann.note,
          );
        })
        .toList(growable: false);

    await repo.upsert(items);
  }

  /// Pull annotations for a specific chapter from the backend and merge into local state.
  /// Server is treated as source of truth for that chapter.
  Future<void> syncFromServerChapter({
    required String translationId,
    required String bookId,
    required int chapter,
  }) async {
    final repo = ref.read(bibleAnnotationsRepositoryProvider);
    final rows = await repo.list(
      translationId: translationId,
      bookId: bookId,
      chapter: chapter,
    );

    final current = state.value ?? const BibleAnnotations();

    // Start from current, but first remove all existing verses for this exact chapter,
    // because server is the source of truth for the chapter.
    final nextMap = Map<String, BibleVerseAnnotation>.from(current.byVerseKey);

    final prefix = '${translationId.toLowerCase()}:${bookId.toUpperCase()}:$chapter:';
    nextMap.removeWhere((k, _) => k.startsWith(prefix));

    var next = BibleAnnotations(byVerseKey: nextMap);

    for (final r in rows) {
      final verseRef = BibleVerseRef(
        translationId: translationId,
        bookId: bookId,
        chapter: chapter,
        verse: r.verse,
      );

      BibleHighlightColor? color;
      final h = (r.highlight ?? '').trim();
      if (h.isNotEmpty) {
        color = BibleHighlightColor.values
            .where((e) => e.name == h)
            .cast<BibleHighlightColor?>()
            .firstWhere((e) => e != null, orElse: () => null);
      }

      next = next.copyWithVerse(
        verseRef,
        BibleVerseAnnotation(
          highlight: color,
          isFavorite: r.isFavorite == true,
          note: r.note,
          updatedAt: null,
        ),
      );
    }

    await _persist(next);
  }

  Future<void> setHighlightForVerses(
    Iterable<BibleVerseRef> refs,
    BibleHighlightColor? color,
  ) async {
    final current = state.value ?? const BibleAnnotations();
    var next = current;
    final now = DateTime.now();

    for (final r in refs) {
      final prev = current.annotationFor(r);
      // When color is null we want to CLEAR highlight, not keep previous.
      final updated = prev.copyWith(
        highlight: color,
        clearHighlight: color == null,
        updatedAt: now,
      );
      next = next.copyWithVerse(r, updated);
    }

    await _persist(next);

    try {
      await _pushToServer(refs);
    } catch (_) {
      // Ignore network/server errors; local cache still works.
    }
  }

  Future<void> toggleFavoriteForVerses(Iterable<BibleVerseRef> refs) async {
    final current = state.value ?? const BibleAnnotations();
    final now = DateTime.now();

    // Toggle strategy for multi-select:
    // - if ANY selected verse is NOT favorite => add favorites to all (nextValue=true)
    // - else (all are favorite) => remove favorites from all (nextValue=false)
    final list = refs.toList(growable: false);
    final anyNotFavorite = list.any((r) => !current.annotationFor(r).isFavorite);
    final nextValue = anyNotFavorite;

    var next = current;
    for (final r in list) {
      final prev = current.annotationFor(r);
      final updated = prev.copyWith(isFavorite: nextValue, updatedAt: now);
      next = next.copyWithVerse(r, updated);
    }

    await _persist(next);

    try {
      await _pushToServer(list);
    } catch (_) {
      // Ignore network/server errors; local cache still works.
    }
  }

  Future<void> setNoteForVerse(BibleVerseRef ref, String? note) async {
    final current = state.value ?? const BibleAnnotations();
    final now = DateTime.now();

    final prev = current.annotationFor(ref);
    final updated = prev.copyWith(note: note, updatedAt: now);
    final next = current.copyWithVerse(ref, updated);

    await _persist(next);

    try {
      await _pushToServer([ref]);
    } catch (_) {
      // Ignore network/server errors; local cache still works.
    }
  }

  Future<void> clearForVerses(Iterable<BibleVerseRef> refs) async {
    final current = state.value ?? const BibleAnnotations();
    var next = current;
    for (final r in refs) {
      next = next.copyWithVerse(r, const BibleVerseAnnotation());
    }
    await _persist(next);

    try {
      await _pushToServer(refs);
    } catch (_) {
      // Ignore network/server errors; local cache still works.
    }
  }
}

final bibleAnnotationsProvider = AsyncNotifierProvider<BibleAnnotationsNotifier, BibleAnnotations>(
  BibleAnnotationsNotifier.new,
);
