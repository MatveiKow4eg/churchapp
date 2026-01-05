import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/errors/app_error.dart';
import '../auth/session_providers.dart';
import 'models/submission_model.dart';
import 'submissions_repository.dart';

final submissionsRepositoryProvider = Provider<SubmissionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubmissionsRepository(apiClient: apiClient);
});

final createSubmissionControllerProvider = AutoDisposeAsyncNotifierProvider<
    CreateSubmissionController,
    SubmissionModel?>(CreateSubmissionController.new);

class CreateSubmissionController
    extends AutoDisposeAsyncNotifier<SubmissionModel?> {
  @override
  Future<SubmissionModel?> build() async => null;

  Future<SubmissionModel> submit({
    required String taskId,
    String? commentUser,
  }) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(submissionsRepositoryProvider);
      final submission = await repo.createSubmission(
        taskId: taskId,
        commentUser: commentUser,
      );

      state = AsyncData(submission);
      return submission;
    } on AppError catch (e, st) {
      // Auth/session handling
      if (e.code == 'UNAUTHORIZED') {
        await ref.read(authTokenProvider.notifier).clearToken();
        ref.invalidate(currentUserProvider);
      }

      state = AsyncError<SubmissionModel?>(e, st);
      rethrow;
    } catch (e, st) {
      state = AsyncError<SubmissionModel?>(e, st);
      rethrow;
    }
  }
}
