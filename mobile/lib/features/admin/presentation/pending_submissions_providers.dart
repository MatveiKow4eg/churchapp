import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../auth/auth_state.dart';
import '../../auth/session_providers.dart';
import '../../submissions/create_submission_controller.dart';
import '../../submissions/models/pending_submission_item.dart';

final pendingSubmissionsProvider = AutoDisposeAsyncNotifierProvider<
    PendingSubmissionsController, List<PendingSubmissionItem>>(
  PendingSubmissionsController.new,
);

class PendingSubmissionsController
    extends AutoDisposeAsyncNotifier<List<PendingSubmissionItem>> {
  @override
  Future<List<PendingSubmissionItem>> build() async {
    final repo = ref.read(submissionsRepositoryProvider);
    return repo.fetchPending(limit: 30, offset: 0);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Centralized session handling for this feature.
  Future<void> handleAppError(AppError e) async {
    if (e.code == 'UNAUTHORIZED') {
      await ref.read(authTokenProvider.notifier).clearToken();
      ref.invalidate(authStateProvider);
      return;
    }

    // NO_CHURCH is handled by UI via router redirect trigger,
    // but we keep the code here for clarity/consistency.
    if (e.code == 'NO_CHURCH') {
      // Nothing to do here; UI will navigate.
      return;
    }
  }
}
