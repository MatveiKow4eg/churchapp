import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../auth/session_providers.dart';
import '../submissions/create_submission_controller.dart';
import '../submissions/models/submission_model.dart';
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
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<TaskModel>> _load() async {
    final tasksRepo = ref.read(tasksRepositoryProvider);
    final submissionsRepo = ref.read(submissionsRepositoryProvider);

    // Load tasks and my submissions in parallel.
    final results = await Future.wait([
      tasksRepo.fetchTasks(activeOnly: true),
      submissionsRepo.fetchMySubmissions(status: null),
    ]);

    final tasks = results[0] as List<TaskModel>;
    final submissions = results[1] as List<SubmissionModel>;

    // Hide tasks that are already submitted or completed.
    // - PENDING: moved to "My submissions" until decision.
    // - APPROVED: completed, should not be shown in active tasks.
    // - REJECTED: task should be available again.
    final hiddenTaskIds = submissions
        .where((s) => s.status == 'PENDING' || s.status == 'APPROVED')
        .map((s) => s.task?.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    return tasks.where((t) => !hiddenTaskIds.contains(t.id)).toList();
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
