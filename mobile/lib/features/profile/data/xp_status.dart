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

    int readCat(String key) {
      final v = rawCategories[key];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

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
        'spiritual': readCat('spiritual'),
        'service': readCat('service'),
        'community': readCat('community'),
        'creativity': readCat('creativity'),
        'reflection': readCat('reflection'),
        'quiz': readCat('quiz'),
        'other': readCat('other'),
      },
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastTaskCompletedAt: parsedLast,
    );
  }
}
