class UserStatsModel {
  const UserStatsModel({
    required this.month,
    required this.tasksApprovedCount,
    required this.pointsEarned,
    required this.pointsSpent,
    required this.netPoints,
    required this.currentBalance,
    required this.topCategories,
  });

  final String month;
  final int tasksApprovedCount;
  final int pointsEarned;
  final int pointsSpent;
  final int netPoints;
  final int currentBalance;
  final List<UserTopCategory> topCategories;

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    final rawTop = json['topCategories'];

    return UserStatsModel(
      month: (json['month'] ?? '').toString(),
      tasksApprovedCount: (json['tasksApprovedCount'] is num)
          ? (json['tasksApprovedCount'] as num).toInt()
          : int.tryParse((json['tasksApprovedCount'] ?? '0').toString()) ?? 0,
      pointsEarned: (json['pointsEarned'] is num)
          ? (json['pointsEarned'] as num).toInt()
          : int.tryParse((json['pointsEarned'] ?? '0').toString()) ?? 0,
      pointsSpent: (json['pointsSpent'] is num)
          ? (json['pointsSpent'] as num).toInt()
          : int.tryParse((json['pointsSpent'] ?? '0').toString()) ?? 0,
      netPoints: (json['netPoints'] is num)
          ? (json['netPoints'] as num).toInt()
          : int.tryParse((json['netPoints'] ?? '0').toString()) ?? 0,
      currentBalance: (json['currentBalance'] is num)
          ? (json['currentBalance'] as num).toInt()
          : int.tryParse((json['currentBalance'] ?? '0').toString()) ?? 0,
      topCategories: rawTop is List
          ? rawTop
              .whereType<Map>()
              .map((e) =>
                  UserTopCategory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <UserTopCategory>[],
    );
  }
}

class UserTopCategory {
  const UserTopCategory({required this.category, required this.count});

  final String category;
  final int count;

  factory UserTopCategory.fromJson(Map<String, dynamic> json) {
    return UserTopCategory(
      category: (json['category'] ?? '').toString(),
      count: (json['count'] is num)
          ? (json['count'] as num).toInt()
          : int.tryParse((json['count'] ?? '0').toString()) ?? 0,
    );
  }
}
