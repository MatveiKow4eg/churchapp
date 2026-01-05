import '../../auth/models/user_model.dart';
import 'church_model.dart';

class JoinChurchResult {
  const JoinChurchResult({
    required this.token,
    required this.user,
    required this.church,
  });

  final String token;
  final UserModel user;
  final ChurchModel church;

  factory JoinChurchResult.fromJson(Map<String, dynamic> json) {
    return JoinChurchResult(
      token: (json['token'] as String?) ?? '',
      user: UserModel.fromJson(
        Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
      ),
      church: ChurchModel.fromJson(
        Map<String, dynamic>.from((json['church'] as Map?) ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'age': user.age,
        'city': user.city,
        'role': user.role,
        'status': user.status,
        'churchId': user.churchId,
      },
      'church': church.toJson(),
    };
  }
}
