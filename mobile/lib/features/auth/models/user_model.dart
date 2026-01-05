class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
    required this.role,
    required this.status,
    required this.churchId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
  final String role;
  final String status;
  final String? churchId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final ageValue = json['age'];
    final age = switch (ageValue) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      age: age,
      city: (json['city'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      churchId: json['churchId']?.toString(),
    );
  }
}
