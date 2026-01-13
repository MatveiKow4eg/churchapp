import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/providers.dart';

class AdminChurchDto {
  const AdminChurchDto({
    required this.id,
    required this.name,
    required this.city,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? city;
  final DateTime createdAt;

  factory AdminChurchDto.fromJson(Map<String, dynamic> json) {
    return AdminChurchDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: json['city']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    required this.churchId,
    required this.createdAt,
    required this.updatedAt,
    required this.avatarUpdatedAt,
    required this.avatarConfig,
  });

  final String id;
  final String? email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final String? churchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? avatarUpdatedAt;
  final Object? avatarConfig;

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: (json['id'] ?? '').toString(),
      email: json['email']?.toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      churchId: json['churchId']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      avatarUpdatedAt: DateTime.tryParse((json['avatarUpdatedAt'] ?? '').toString()),
      avatarConfig: json['avatarConfig'],
    );
  }
}

final superadminApiProvider = Provider<SuperAdminApi>((ref) {
  final client = ref.read(apiClientProvider);
  return SuperAdminApi(client);
});

class SuperAdminApi {
  SuperAdminApi(this._client);

  final ApiClient _client;

  Future<List<AdminChurchDto>> listChurches() async {
    final res = await _client.dio.get('/admin/churches');
    final data = res.data;

    final items =
        (data is Map ? (data['items'] as List? ?? const []) : const [])
            .whereType<Map>()
            .map((m) => AdminChurchDto.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false);

    return items;
  }

  Future<AdminChurchDto> createChurch(
      {required String name, String? city}) async {
    final res = await _client.dio.post(
      '/admin/churches',
      data: {
        'name': name,
        'city': city,
      },
    );

    final data = res.data;
    final church = (data is Map ? (data['church'] as Map?) : null)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return AdminChurchDto.fromJson(church);
  }

  Future<List<AdminUserDto>> listUsers() async {
    final res = await _client.dio.get('/admin/users');
    final data = res.data;

    final items =
        (data is Map ? (data['items'] as List? ?? const []) : const [])
            .whereType<Map>()
            .map((m) => AdminUserDto.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false);

    return items;
  }

  Future<AdminUserDto> updateUser({
    required String id,
    String? firstName,
    String? lastName,
    String? role,
    String? status,
    String? churchId,
  }) async {
    final res = await _client.dio.patch(
      '/admin/users/$id',
      data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (role != null) 'role': role,
        if (status != null) 'status': status,
        // explicit null is valid to unlink
        'churchId': churchId,
      },
    );

    final data = res.data;
    final user = (data is Map ? (data['user'] as Map?) : null)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return AdminUserDto.fromJson(user);
  }
}

final superadminChurchesProvider =
    FutureProvider<List<AdminChurchDto>>((ref) async {
  return ref.read(superadminApiProvider).listChurches();
});

final superadminUsersProvider = FutureProvider<List<AdminUserDto>>((ref) async {
  return ref.read(superadminApiProvider).listUsers();
});

final superadminCreateChurchProvider =
    NotifierProvider<SuperadminCreateChurchNotifier, AsyncValue<void>>(
  SuperadminCreateChurchNotifier.new,
);

class SuperadminCreateChurchNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> createChurch({required String name, String? city}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(superadminApiProvider)
          .createChurch(name: name, city: city);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
