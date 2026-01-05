import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../auth/session_providers.dart';
import 'models/task_model.dart';
import 'tasks_repository.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TasksRepository(apiClient: apiClient);
});

final tasksListProvider =
    AutoDisposeAsyncNotifierProvider<TasksListNotifier, List<TaskModel>>(
  TasksListNotifier.new,
);

final taskByIdProvider =
    FutureProvider.autoDispose.family<TaskModel, String>((ref, id) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.fetchTaskById(id);
});

class TasksListNotifier extends AutoDisposeAsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final repo = ref.read(tasksRepositoryProvider);
    return repo.fetchTasks(activeOnly: true);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tasksRepositoryProvider);
      return repo.fetchTasks(activeOnly: true);
    });
  }

  Future<void> handleAuthErrors(Object err) async {
    if (err is! Exception) return;

    final s = err.toString();

    if (s.contains('AppError(code: NO_CHURCH') || s.contains('NO_CHURCH')) {
      // Redirect to /church should be triggered by UI.
      return;
    }

    if (s.contains('AppError(code: UNAUTHORIZED') ||
        s.contains('UNAUTHORIZED')) {
      await ref.read(authTokenProvider.notifier).clearToken();
      ref.invalidate(currentUserProvider);
    }
  }
}
