import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bible_providers.dart';

Future<void> runBibleSmokeTest(WidgetRef ref) async {
  final repo = ref.read(bibleRepositoryProvider);

  final books = await repo.getRusSynBooks();
  debugPrint('Bible smoke: rus_syn books loaded: ${books.length}');

  final chapter = await repo.getRusSynChapter('GEN', 1);
  if (chapter.verses.isNotEmpty) {
    debugPrint('Bible smoke: GEN 1 verses loaded: ${chapter.verses.length}');
  } else {
    debugPrint('Bible smoke: GEN 1 loaded (verses empty); raw ok');
  }
}
