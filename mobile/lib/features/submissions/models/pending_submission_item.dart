class PendingSubmissionItem {
  const PendingSubmissionItem({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.commentUser,
    required this.user,
    required this.task,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String? commentUser;
  final PendingSubmissionUser user;
  final PendingSubmissionTask task;

  factory PendingSubmissionItem.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final createdAt = switch (createdAtRaw) {
      final String s => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0),
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      final num n => DateTime.fromMillisecondsSinceEpoch(n.toInt()),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };

    final userRaw = json['user'];
    final taskRaw = json['task'];

    return PendingSubmissionItem(
      id: json['id']?.toString() ?? '',
      status: (json['status'] ?? '') as String,
      createdAt: createdAt,
      commentUser: (json['commentUser'] as String?)?.trim().isEmpty == true
          ? null
          : (json['commentUser'] as String?),
      user: userRaw is Map
          ? PendingSubmissionUser.fromJson(Map<String, dynamic>.from(userRaw))
          : const PendingSubmissionUser(id: '', firstName: '', lastName: '', age: 0, city: ''),
      task: taskRaw is Map
          ? PendingSubmissionTask.fromJson(Map<String, dynamic>.from(taskRaw))
          : const PendingSubmissionTask(id: '', title: '', pointsReward: 0, category: ''),
    );
  }
}

class PendingSubmissionUser {
  const PendingSubmissionUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
  });

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String city;

  factory PendingSubmissionUser.fromJson(Map<String, dynamic> json) {
    final ageValue = json['age'];
    final age = switch (ageValue) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return PendingSubmissionUser(
      id: json['id']?.toString() ?? '',
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      age: age,
      city: (json['city'] ?? '') as String,
    );
  }

  String get fullName {
    final n = '${firstName.trim()} ${lastName.trim()}'.trim();
    return n.isEmpty ? 'Пользователь' : n;
  }
}

class PendingSubmissionTask {
  const PendingSubmissionTask({
    required this.id,
    required this.title,
    required this.pointsReward,
    required this.category,
  });

  final String id;
  final String title;
  final int pointsReward;
  final String category;

  factory PendingSubmissionTask.fromJson(Map<String, dynamic> json) {
    final pointsValue = json['pointsReward'];
    final pointsReward = switch (pointsValue) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return PendingSubmissionTask(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '') as String,
      pointsReward: pointsReward,
      category: (json['category'] ?? '') as String,
    );
  }
}
