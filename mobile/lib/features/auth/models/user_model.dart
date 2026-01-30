class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
    required this.email,
    required this.role,
    required this.status,
    required this.churchId,
    this.churchName,
    this.churchCity,
    required this.avatarConfig,
    required this.avatarUpdatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
  final String email;
  final String role;
  final String status;
  final String? churchId;

  /// Optional church data returned by backend in /auth/me response.
  /// Backend returns it as a sibling object `{ user, church }`, not inside `user`.
  final String? churchName;
  final String? churchCity;

  final Map<String, dynamic>? avatarConfig;
  final DateTime? avatarUpdatedAt;

  bool get hasAvatar => avatarConfig != null && avatarConfig!.isNotEmpty;

  String? get churchLabel {
    final name = (churchName ?? '').trim();
    final city = (churchCity ?? '').trim();
    if (name.isEmpty) return null;
    return city.isEmpty ? name : '$name ($city)';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // /auth/me returns `{ user, church, balance }`. Some callers might pass
    // either the whole envelope or just `user`.
    final envelopeUser = json['user'];
    final Map<String, dynamic> userJson = envelopeUser is Map
        ? Map<String, dynamic>.from(envelopeUser)
        : json;

    final ageValue = userJson['age'];
    final age = switch (ageValue) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    final avatarConfigRaw = userJson['avatarConfig'];
    final avatarConfig = (avatarConfigRaw is Map)
        ? avatarConfigRaw.cast<String, dynamic>()
        : null;

    final avatarUpdatedAtRaw = userJson['avatarUpdatedAt'];
    final avatarUpdatedAt = avatarUpdatedAtRaw != null
        ? DateTime.tryParse(avatarUpdatedAtRaw.toString())
        : null;

    final rawChurch = json['church'];
    final Map<String, dynamic>? churchJson = rawChurch is Map
        ? Map<String, dynamic>.from(rawChurch)
        : null;

    return UserModel(
      id: userJson['id']?.toString() ?? '',
      firstName: (userJson['firstName'] ?? '') as String,
      lastName: (userJson['lastName'] ?? '') as String,
      age: age,
      city: (userJson['city'] ?? '') as String,
      email: (userJson['email'] ?? '') as String,
      role: (userJson['role'] ?? '') as String,
      status: (userJson['status'] ?? '') as String,
      churchId: userJson['churchId']?.toString(),
      churchName: churchJson?['name']?.toString(),
      churchCity: churchJson?['city']?.toString(),
      avatarConfig: avatarConfig,
      avatarUpdatedAt: avatarUpdatedAt,
    );
  }
}
