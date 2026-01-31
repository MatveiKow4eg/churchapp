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

class PointsLedgerEntryDto {
  const PointsLedgerEntryDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.reason,
    required this.actorId,
  });

  final String id;
  final String type;
  final int amount;
  final DateTime createdAt;
  final String? reason;
  final String? actorId;

  factory PointsLedgerEntryDto.fromJson(Map<String, dynamic> json) {
    final metaAny = json['meta'];
    String? reason;
    String? actorId;
    if (metaAny is Map) {
      final meta = Map<String, dynamic>.from(metaAny);
      final r = meta['reason'];
      final a = meta['actorId'];
      if (r is String && r.trim().isNotEmpty) reason = r.trim();
      if (a is String && a.trim().isNotEmpty) actorId = a.trim();
    }

    final createdAtAny = json['createdAt'];
    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (createdAtAny is String) {
      createdAt = DateTime.tryParse(createdAtAny) ?? createdAt;
    }

    return PointsLedgerEntryDto(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toInt() : 0,
      createdAt: createdAt.toLocal(),
      reason: reason,
      actorId: actorId,
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

  Future<List<PointsLedgerEntryDto>> getUserPointsLedger({
    required String userId,
    int take = 20,
  }) async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/admin/users/$userId/points/ledger',
        queryParameters: {'take': take},
      );
      final data = resp.data ?? const <String, dynamic>{};
      final itemsAny = data['items'];
      if (itemsAny is! List) return const [];
      return itemsAny
          .whereType<Map>()
          .map((m) => PointsLedgerEntryDto.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
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
