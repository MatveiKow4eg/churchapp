import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import 'admin_points_repository.dart';

final adminPointsRepositoryProvider = Provider<AdminPointsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminPointsRepository(apiClient: apiClient);
});

final churchUsersProvider = FutureProvider<List<ChurchUserShortDto>>((ref) async {
  final repo = ref.watch(adminPointsRepositoryProvider);
  return repo.listChurchUsers();
});

/// Holds currently selected userId in the points admin tab.
final selectedPointsUserIdProvider = StateProvider<String?>((ref) => null);

/// Fetches points balance for selected user.
final selectedUserPointsProvider = FutureProvider<UserPointsDto?>((ref) async {
  final userId = ref.watch(selectedPointsUserIdProvider);
  if (userId == null || userId.trim().isEmpty) return null;
  final repo = ref.watch(adminPointsRepositoryProvider);
  return repo.getUserPoints(userId: userId);
});

final selectedUserPointsLedgerProvider = FutureProvider<List<PointsLedgerEntryDto>>((ref) async {
  final userId = ref.watch(selectedPointsUserIdProvider);
  if (userId == null || userId.trim().isEmpty) return const [];
  final repo = ref.watch(adminPointsRepositoryProvider);
  return repo.getUserPointsLedger(userId: userId, take: 20);
});
