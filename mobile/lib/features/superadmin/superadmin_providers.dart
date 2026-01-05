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
}

final superadminChurchesProvider =
    FutureProvider<List<AdminChurchDto>>((ref) async {
  return ref.read(superadminApiProvider).listChurches();
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
