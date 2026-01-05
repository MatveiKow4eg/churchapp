class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pointsReward,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int pointsReward;
  final bool isActive;
  final DateTime createdAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final pr = json['pointsReward'];
    final points = switch (pr) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);

    return TaskModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      pointsReward: points,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: createdAt,
    );
  }
}
