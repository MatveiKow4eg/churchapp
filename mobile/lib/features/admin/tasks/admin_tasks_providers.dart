import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../auth/session_providers.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/tasks_providers.dart';

enum AdminTasksFilter { all, active, inactive }

final adminTasksFilterProvider =
    StateProvider.autoDispose<AdminTasksFilter>((ref) {
  return AdminTasksFilter.all;
});

final adminTasksSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final adminTasksListProvider = AutoDisposeAsyncNotifierProvider<
    AdminTasksListController, List<TaskModel>>(
  AdminTasksListController.new,
);

class AdminTasksListController extends AutoDisposeAsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final repo = ref.read(tasksRepositoryProvider);

    // For admin list we need both active/inactive -> activeOnly=false
    return repo.fetchTasks(activeOnly: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> handleAppError(AppError e) async {
    if (e.code == 'UNAUTHORIZED') {
      await ref.read(authTokenProvider.notifier).clearToken();
      ref.invalidate(currentUserProvider);
      return;
    }
  }
}

final adminTaskByIdProvider = FutureProvider.autoDispose.family<TaskModel, String>(
  (ref, id) async {
    final repo = ref.read(tasksRepositoryProvider);
    return repo.fetchTaskById(id);
  },
);
