import 'user_model.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel? user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? '') as String;

    final rawUser = json['user'];
    UserModel? user;
    if (rawUser is Map) {
      user = UserModel.fromJson(rawUser.cast<String, dynamic>());
    }

    return AuthResult(token: token, user: user);
  }
}
