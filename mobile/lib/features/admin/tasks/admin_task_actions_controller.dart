import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../auth/auth_state.dart';
import '../../auth/session_providers.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/tasks_providers.dart';
import 'admin_tasks_providers.dart';

final adminTaskActionsControllerProvider =
    NotifierProvider<AdminTaskActionsController, Set<String>>(
  AdminTaskActionsController.new,
);

/// Holds taskIds that are currently being updated/deactivated.
class AdminTaskActionsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isLoading(String taskId) => state.contains(taskId);

  Future<TaskModel> deactivate(String taskId) async {
    _setLoading(taskId, true);

    try {
      final repo = ref.read(tasksRepositoryProvider);
      final updated = await repo.deactivateTask(taskId);
      await ref.read(adminTasksListProvider.notifier).refresh();
      return updated;
    } on AppError catch (e) {
      await _handleSessionErrors(e);
      rethrow;
    } finally {
      _setLoading(taskId, false);
    }
  }

  void _setLoading(String taskId, bool value) {
    if (value) {
      state = {...state, taskId};
    } else {
      final next = {...state}..remove(taskId);
      state = next;
    }
  }

  Future<void> _handleSessionErrors(AppError e) async {
    if (e.code == 'UNAUTHORIZED') {
      await ref.read(authTokenProvider.notifier).clearToken();
      ref.invalidate(authStateProvider);
    }
  }
}
