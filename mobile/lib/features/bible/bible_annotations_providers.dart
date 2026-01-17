import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bible_annotations_storage.dart';
import 'bible_progress_providers.dart' show flutterSecureStorageProvider;

final bibleAnnotationsStorageProvider = Provider<BibleAnnotationsStorage>((ref) {
  return BibleAnnotationsStorage(ref.watch(flutterSecureStorageProvider));
});

class BibleAnnotationsNotifier extends AsyncNotifier<BibleAnnotations> {
  @override
  Future<BibleAnnotations> build() async {
    return ref.watch(bibleAnnotationsStorageProvider).load();
  }

  Future<void> _persist(BibleAnnotations next) async {
    state = AsyncData(next);
    await ref.read(bibleAnnotationsStorageProvider).save(next);
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
  }

  Future<void> toggleFavoriteForVerses(Iterable<BibleVerseRef> refs) async {
    final current = state.value ?? const BibleAnnotations();
    final now = DateTime.now();

    // Toggle based on the first verse state.
    final first = refs.isEmpty ? null : refs.first;
    final currentValue = first == null ? false : current.annotationFor(first).isFavorite;
    final nextValue = !currentValue;

    var next = current;
    for (final r in refs) {
      final prev = current.annotationFor(r);
      final updated = prev.copyWith(isFavorite: nextValue, updatedAt: now);
      next = next.copyWithVerse(r, updated);
    }

    await _persist(next);
  }

  Future<void> setNoteForVerse(BibleVerseRef ref, String? note) async {
    final current = state.value ?? const BibleAnnotations();
    final now = DateTime.now();

    final prev = current.annotationFor(ref);
    final updated = prev.copyWith(note: note, updatedAt: now);
    final next = current.copyWithVerse(ref, updated);

    await _persist(next);
  }

  Future<void> clearForVerses(Iterable<BibleVerseRef> refs) async {
    final current = state.value ?? const BibleAnnotations();
    var next = current;
    for (final r in refs) {
      next = next.copyWithVerse(r, const BibleVerseAnnotation());
    }
    await _persist(next);
  }
}

final bibleAnnotationsProvider =
    AsyncNotifierProvider<BibleAnnotationsNotifier, BibleAnnotations>(
  BibleAnnotationsNotifier.new,
);
