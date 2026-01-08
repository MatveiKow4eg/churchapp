import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bible_progress_providers.dart' show flutterSecureStorageProvider;
import 'bible_reader_settings_storage.dart';

final bibleReaderSettingsStorageProvider = Provider<BibleReaderSettingsStorage>((ref) {
  return BibleReaderSettingsStorage(ref.watch(flutterSecureStorageProvider));
});

class BibleReaderSettingsNotifier extends AsyncNotifier<BibleReaderSettings> {
  @override
  Future<BibleReaderSettings> build() async {
    return ref.watch(bibleReaderSettingsStorageProvider).load();
  }

  Future<void> setFontSize(double v) async {
    final storage = ref.read(bibleReaderSettingsStorageProvider);
    final current = state.value ?? BibleReaderSettings.defaults;
    final next = current.copyWith(fontSize: v);
    state = AsyncData(next);
    await storage.save(next);
  }

  Future<void> setLineHeight(double v) async {
    final storage = ref.read(bibleReaderSettingsStorageProvider);
    final current = state.value ?? BibleReaderSettings.defaults;
    final next = current.copyWith(lineHeight: v);
    state = AsyncData(next);
    await storage.save(next);
  }

  Future<void> setHorizontalPadding(double v) async {
    final storage = ref.read(bibleReaderSettingsStorageProvider);
    final current = state.value ?? BibleReaderSettings.defaults;
    final next = current.copyWith(horizontalPadding: v);
    state = AsyncData(next);
    await storage.save(next);
  }

  Future<void> setShowVerseNumbers(bool v) async {
    final storage = ref.read(bibleReaderSettingsStorageProvider);
    final current = state.value ?? BibleReaderSettings.defaults;
    final next = current.copyWith(showVerseNumbers: v);
    state = AsyncData(next);
    await storage.save(next);
  }

  Future<void> resetToDefaults() async {
    final storage = ref.read(bibleReaderSettingsStorageProvider);
    final next = BibleReaderSettings.defaults;
    state = const AsyncData(BibleReaderSettings.defaults);
    await storage.save(next);
  }
}

final bibleReaderSettingsProvider =
    AsyncNotifierProvider<BibleReaderSettingsNotifier, BibleReaderSettings>(
  BibleReaderSettingsNotifier.new,
);
