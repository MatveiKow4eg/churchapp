import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'bible_progress_storage.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final bibleProgressStorageProvider = Provider<BibleProgressStorage>((ref) {
  return BibleProgressStorage(ref.watch(flutterSecureStorageProvider));
});

final lastBiblePositionProvider = FutureProvider<BibleLastPosition?>((ref) async {
  final storage = ref.watch(bibleProgressStorageProvider);
  return storage.loadLastPosition();
});
