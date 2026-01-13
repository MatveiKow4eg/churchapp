class ChurchStatsModel {
  ChurchStatsModel({
    required this.month,
    required this.activeUsersCount,
    required this.totalMembersCount,
    required this.approvedSubmissionsCount,
    required this.pendingSubmissionsCount,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.topUsers,
    required this.topTasks,
    required this.members,
  });

  final String month;
  final int activeUsersCount;
  final int totalMembersCount;
  final int approvedSubmissionsCount;
  final int pendingSubmissionsCount;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final List<ChurchTopUser> topUsers;
  final List<ChurchTopTask> topTasks;
  final List<ChurchMember> members;

  int get netPoints => totalPointsEarned - totalPointsSpent;

  factory ChurchStatsModel.fromJson(Map<String, dynamic> json) {
    final topUsersRaw = json['topUsers'];
    final topTasksRaw = json['topTasks'];
    final membersRaw = json['members'];

    return ChurchStatsModel(
      month: (json['month'] ?? '').toString(),
      activeUsersCount: (json['activeUsersCount'] as num?)?.toInt() ?? 0,
      totalMembersCount: (json['totalMembersCount'] as num?)?.toInt() ?? 0,
      approvedSubmissionsCount:
          (json['approvedSubmissionsCount'] as num?)?.toInt() ?? 0,
      pendingSubmissionsCount:
          (json['pendingSubmissionsCount'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
      totalPointsSpent: (json['totalPointsSpent'] as num?)?.toInt() ?? 0,
      topUsers: (topUsersRaw is List)
          ? topUsersRaw
              .whereType<Map>()
              .map((m) => ChurchTopUser.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .toList()
          : const [],
      topTasks: (topTasksRaw is List)
          ? topTasksRaw
              .whereType<Map>()
              .map((m) => ChurchTopTask.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .toList()
          : const [],
      members: (membersRaw is List)
          ? membersRaw
              .whereType<Map>()
              .map((m) => ChurchMember.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .toList()
          : const [],
    );
  }
}

class ChurchMember {
  const ChurchMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.avatarConfig,
    this.avatarUpdatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String status;
  final Map<String, dynamic>? avatarConfig;
  final DateTime? avatarUpdatedAt;

  String get fullName {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isEmpty ? '—' : name;
  }

  factory ChurchMember.fromJson(Map<String, dynamic> json) {
    final avatarConfigRaw = json['avatarConfig'];
    final avatarConfig = (avatarConfigRaw is Map)
        ? avatarConfigRaw.cast<String, dynamic>()
        : null;

    final avatarUpdatedAtRaw = json['avatarUpdatedAt'];
    final avatarUpdatedAt = avatarUpdatedAtRaw != null
        ? DateTime.tryParse(avatarUpdatedAtRaw.toString())
        : null;

    return ChurchMember(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      avatarConfig: avatarConfig,
      avatarUpdatedAt: avatarUpdatedAt,
    );
  }
}

class ChurchTopUser {
  ChurchTopUser({required this.user, required this.netPoints});

  final ChurchUserShort user;
  final int netPoints;

  factory ChurchTopUser.fromJson(Map<String, dynamic> json) {
    final userAny = json['user'];
    return ChurchTopUser(
      user: userAny is Map
          ? ChurchUserShort.fromJson(
              userAny.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const ChurchUserShort(id: '', firstName: '', lastName: ''),
      netPoints: (json['netPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChurchTopTask {
  ChurchTopTask({required this.task, required this.approvedCount});

  final ChurchTaskShort task;
  final int approvedCount;

  factory ChurchTopTask.fromJson(Map<String, dynamic> json) {
    final taskAny = json['task'];
    return ChurchTopTask(
      task: taskAny is Map
          ? ChurchTaskShort.fromJson(
              taskAny.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const ChurchTaskShort(id: '', title: ''),
      approvedCount: (json['approvedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChurchUserShort {
  const ChurchUserShort({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarConfig,
    this.avatarUpdatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Map<String, dynamic>? avatarConfig;
  final DateTime? avatarUpdatedAt;

  String get fullName {
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();
    return name.isEmpty ? '—' : name;
  }

  factory ChurchUserShort.fromJson(Map<String, dynamic> json) {
    final avatarConfigRaw = json['avatarConfig'];
    final avatarConfig = (avatarConfigRaw is Map)
        ? avatarConfigRaw.cast<String, dynamic>()
        : null;

    final avatarUpdatedAtRaw = json['avatarUpdatedAt'];
    final avatarUpdatedAt = avatarUpdatedAtRaw != null
        ? DateTime.tryParse(avatarUpdatedAtRaw.toString())
        : null;

    return ChurchUserShort(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      avatarConfig: avatarConfig,
      avatarUpdatedAt: avatarUpdatedAt,
    );
  }
}

class ChurchTaskShort {
  const ChurchTaskShort({required this.id, required this.title});

  final String id;
  final String title;

  factory ChurchTaskShort.fromJson(Map<String, dynamic> json) {
    return ChurchTaskShort(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
    );
  }
}
