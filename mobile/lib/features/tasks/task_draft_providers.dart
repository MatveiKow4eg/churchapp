import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'task_draft_storage.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final taskDraftStorageProvider = Provider<TaskDraftStorage>((ref) {
  return TaskDraftStorage(ref.watch(flutterSecureStorageProvider));
});
