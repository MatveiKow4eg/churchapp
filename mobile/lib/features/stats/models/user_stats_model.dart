class UserStatsModel {
  const UserStatsModel({
    required this.month,
    required this.tasksApprovedCount,
    required this.tasksRejectedCount,
    required this.pointsEarned,
    required this.pointsSpent,
    required this.currentBalance,
    required this.topCategories,
  });

  final String month;
  final int tasksApprovedCount;
  final int tasksRejectedCount;
  final int pointsEarned;
  final int pointsSpent;
  final int currentBalance;
  final List<UserTopCategory> topCategories;

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    final rawTop = json['topCategories'];

    int readInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    return UserStatsModel(
      month: (json['month'] ?? '').toString(),
      tasksApprovedCount: readInt(json['tasksApprovedCount']),
      tasksRejectedCount: readInt(json['tasksRejectedCount']),
      pointsEarned: readInt(json['pointsEarned']),
      pointsSpent: readInt(json['pointsSpent']),
      currentBalance: readInt(json['currentBalance']),
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
