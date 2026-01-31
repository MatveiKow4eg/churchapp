import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ChurchUserShortDto {
  const ChurchUserShortDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.avatarConfig,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Map<String, dynamic>? avatarConfig;

  String get fullName => ('${firstName.trim()} ${lastName.trim()}').trim();

  factory ChurchUserShortDto.fromJson(Map<String, dynamic> json) {
    final cfgAny = json['avatarConfig'];
    Map<String, dynamic>? cfg;
    if (cfgAny is Map) {
      cfg = Map<String, dynamic>.from(cfgAny);
    }

    return ChurchUserShortDto(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      avatarConfig: cfg,
    );
  }
}

class UserPointsDto {
  const UserPointsDto({
    required this.userId,
    required this.churchId,
    required this.balance,
  });

  final String userId;
  final String churchId;
  final int balance;

  factory UserPointsDto.fromJson(Map<String, dynamic> json) {
    return UserPointsDto(
      userId: (json['userId'] ?? '').toString(),
      churchId: (json['churchId'] ?? '').toString(),
      balance: (json['balance'] is num) ? (json['balance'] as num).toInt() : 0,
    );
  }
}

class AdminPointsRepository {
  AdminPointsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ChurchUserShortDto>> listChurchUsers() async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>('/admin/users/church');
      // ignore: avoid_print
      print('[admin][points] GET /admin/users/church status=${resp.statusCode}');
      final data = resp.data ?? const <String, dynamic>{};
      final itemsAny = data['items'];
      if (itemsAny is! List) return const [];
      return itemsAny
          .whereType<Map>()
          .map((m) => ChurchUserShortDto.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<UserPointsDto> getUserPoints({required String userId}) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>('/admin/users/$userId/points');
      return UserPointsDto.fromJson(resp.data ?? const <String, dynamic>{});
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }

  Future<int> adjustPoints({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    try {
      final resp = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/points/adjust',
        data: {
          'userId': userId,
          'amount': amount,
          'reason': reason,
        },
      );

      final data = resp.data ?? const <String, dynamic>{};
      final balAny = data['balance'];
      if (balAny is num) return balAny.toInt();
      return 0;
    } on DioException catch (e) {
      throw ApiClient.mapDioError(e);
    } catch (e) {
      throw ApiClient.mapDioError(e);
    }
  }
}
