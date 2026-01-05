import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/session_providers.dart';
import 'church_providers.dart';
import 'models/join_church_result.dart';

final joinChurchControllerProvider =
    AutoDisposeAsyncNotifierProvider<JoinChurchController, JoinChurchState>(
        JoinChurchController.new);

class JoinChurchState {
  const JoinChurchState({required this.joiningChurchId});

  final String? joiningChurchId;
}

class JoinChurchController extends AutoDisposeAsyncNotifier<JoinChurchState> {
  @override
  Future<JoinChurchState> build() async {
    return const JoinChurchState(joiningChurchId: null);
  }

  Future<JoinChurchResult> join({required String churchId}) async {
    // Keep in state which card is loading (so UI can show spinner on that card)
    state = const AsyncLoading<JoinChurchState>().copyWithPrevious(
      AsyncData(JoinChurchState(joiningChurchId: churchId)),
    );

    try {
      final repo = ref.read(churchRepositoryProvider);
      final result = await repo.joinChurch(churchId: churchId);

      // Save new token via centralized auth token provider
      await ref.read(authTokenProvider.notifier).setToken(result.token);

      // Refresh global auth state (will fetch /auth/me and detect churchId)
      ref.invalidate(currentUserProvider);

      // Reset join state after success
      state = const AsyncData(JoinChurchState(joiningChurchId: null));

      return result;
    } catch (e, st) {
      // Keep previous joining id so UI doesn't get stuck without knowing which card was loading.
      state = AsyncError<JoinChurchState>(e, st).copyWithPrevious(
        AsyncData(JoinChurchState(joiningChurchId: churchId)),
      );
      rethrow;
    }
  }
}
