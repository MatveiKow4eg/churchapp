import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores draft answers for task submissions so they survive app restarts.
///
/// Keyed by taskId.
class TaskDraftStorage {
  TaskDraftStorage(this._storage);

  final FlutterSecureStorage _storage;

  static String _key(String taskId) => 'task_draft_comment:$taskId';

  Future<String?> loadCommentDraft(String taskId) async {
    final v = await _storage.read(key: _key(taskId));
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> saveCommentDraft(String taskId, String text) async {
    // Avoid writing megabytes; keep it sane.
    final trimmed = text;
    if (trimmed.isEmpty) {
      await clearCommentDraft(taskId);
      return;
    }

    // Hard cap to prevent storage bloat.
    final capped = trimmed.length > 10000 ? trimmed.substring(0, 10000) : trimmed;
    await _storage.write(key: _key(taskId), value: capped);
  }

  Future<void> clearCommentDraft(String taskId) async {
    await _storage.delete(key: _key(taskId));
  }
}
