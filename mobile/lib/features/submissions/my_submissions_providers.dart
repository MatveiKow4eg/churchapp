import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_error.dart';
import '../auth/session_providers.dart';
import 'create_submission_controller.dart';
import 'models/submission_model.dart';

enum MySubmissionsFilter {
  all,
  pending,
  approved,
  rejected,
}

String? _filterToApiStatus(MySubmissionsFilter f) {
  return switch (f) {
    MySubmissionsFilter.all => null,
    MySubmissionsFilter.pending => 'PENDING',
    MySubmissionsFilter.approved => 'APPROVED',
    MySubmissionsFilter.rejected => 'REJECTED',
  };
}

final mySubmissionsFilterProvider = StateProvider<MySubmissionsFilter>((ref) {
  return MySubmissionsFilter.all;
});

final mySubmissionsListProvider = AutoDisposeAsyncNotifierProvider<
    MySubmissionsListNotifier,
    List<SubmissionModel>>(MySubmissionsListNotifier.new);

class MySubmissionsListNotifier
    extends AutoDisposeAsyncNotifier<List<SubmissionModel>> {
  @override
  Future<List<SubmissionModel>> build() async {
    final filter = ref.watch(mySubmissionsFilterProvider);
    final repo = ref.read(submissionsRepositoryProvider);
    return repo.fetchMySubmissions(status: _filterToApiStatus(filter));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(mySubmissionsFilterProvider);
      final repo = ref.read(submissionsRepositoryProvider);
      return repo.fetchMySubmissions(status: _filterToApiStatus(filter));
    });
  }

  Future<void> handleAuth(AppError e) async {
    if (e.code == 'UNAUTHORIZED') {
      await ref.read(authTokenProvider.notifier).clearToken();
      ref.invalidate(currentUserProvider);
    }
  }
}
