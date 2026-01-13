class XpStatus {
  final int level;
  final String levelName;
  final int levelXp;
  final int nextLevelXp;
  final double progress; // 0..1
  final Map<String, int> categories; // spiritual/service/community/creativity/reflection/other
  final int streakDays;
  final DateTime? lastTaskCompletedAt;

  const XpStatus({
    required this.level,
    required this.levelName,
    required this.levelXp,
    required this.nextLevelXp,
    required this.progress,
    required this.categories,
    required this.streakDays,
    required this.lastTaskCompletedAt,
  });

  factory XpStatus.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    DateTime? parsedLast;
    final rawLast = json['lastTaskCompletedAt'];
    if (rawLast is String && rawLast.isNotEmpty) {
      parsedLast = DateTime.tryParse(rawLast);
    }

    return XpStatus(
      level: (json['level'] as num).toInt(),
      levelName: (json['levelName'] as String?) ?? '',
      levelXp: (json['levelXp'] as num).toInt(),
      nextLevelXp: (json['nextLevelXp'] as num).toInt(),
      progress: (json['progress'] as num).toDouble(),
      categories: {
        'spiritual': (rawCategories['spiritual'] as num?)?.toInt() ?? 0,
        'service': (rawCategories['service'] as num?)?.toInt() ?? 0,
        'community': (rawCategories['community'] as num?)?.toInt() ?? 0,
        'creativity': (rawCategories['creativity'] as num?)?.toInt() ?? 0,
        'reflection': (rawCategories['reflection'] as num?)?.toInt() ?? 0,
        'other': (rawCategories['other'] as num?)?.toInt() ?? 0,
      },
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastTaskCompletedAt: parsedLast,
    );
  }
}
