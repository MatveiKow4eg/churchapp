class SubmissionTaskInfo {
  const SubmissionTaskInfo({
    required this.id,
    required this.title,
    required this.pointsReward,
    required this.category,
  });

  final String id;
  final String title;
  final int pointsReward;
  final String category;

  factory SubmissionTaskInfo.fromJson(Map<String, dynamic> json) {
    final pr = json['pointsReward'];
    final points = switch (pr) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return SubmissionTaskInfo(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      pointsReward: points,
      category: (json['category'] as String?) ?? '',
    );
  }
}

class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.commentUser,
    this.commentAdmin,
    this.rewardPointsApplied,
    this.task,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? commentUser;
  final String? commentAdmin;
  final int? rewardPointsApplied;
  final SubmissionTaskInfo? task;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(Object? v) {
      if (v is String)
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? parseNullableDt(Object? v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rpa = json['rewardPointsApplied'];
    final reward = switch (rpa) {
      null => null,
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };

    final rawTask = json['task'];

    return SubmissionModel(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      createdAt: parseDt(json['createdAt']),
      decidedAt: parseNullableDt(json['decidedAt']),
      commentUser: json['commentUser'] as String?,
      commentAdmin: json['commentAdmin'] as String?,
      rewardPointsApplied: reward,
      task: rawTask is Map
          ? SubmissionTaskInfo.fromJson(Map<String, dynamic>.from(rawTask))
          : null,
    );
  }
}
