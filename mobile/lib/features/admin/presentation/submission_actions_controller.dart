import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../auth/auth_state.dart';
import '../../auth/session_providers.dart';
import '../../submissions/create_submission_controller.dart';
import '../../submissions/models/submission_action_result.dart';
import 'pending_submissions_providers.dart';

final submissionActionsControllerProvider =
    NotifierProvider<SubmissionActionsController, Set<String>>(
  SubmissionActionsController.new,
);

/// Holds a set of submissionIds that are currently being processed
/// (approve/reject request in-flight).
class SubmissionActionsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isLoading(String submissionId) => state.contains(submissionId);

  Future<SubmissionActionResult> approve(
    String submissionId, {
    String? commentAdmin,
  }) async {
    _setLoading(submissionId, true);

    try {
      final repo = ref.read(submissionsRepositoryProvider);
      final res = await repo.approve(submissionId, commentAdmin: commentAdmin);

      // Remove item from pending list by refreshing.
      await ref.read(pendingSubmissionsProvider.notifier).refresh();

      return res;
    } on AppError catch (e) {
      await _handleSessionErrors(e);
      rethrow;
    } finally {
      _setLoading(submissionId, false);
    }
  }

  Future<SubmissionActionResult> reject(
    String submissionId, {
    String? commentAdmin,
  }) async {
    _setLoading(submissionId, true);

    try {
      final repo = ref.read(submissionsRepositoryProvider);
      final res = await repo.reject(submissionId, commentAdmin: commentAdmin);

      // Remove item from pending list by refreshing.
      await ref.read(pendingSubmissionsProvider.notifier).refresh();

      return res;
    } on AppError catch (e) {
      await _handleSessionErrors(e);
      rethrow;
    } finally {
      _setLoading(submissionId, false);
    }
  }

  void _setLoading(String submissionId, bool value) {
    if (value) {
      state = {...state, submissionId};
    } else {
      final next = {...state}..remove(submissionId);
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
