import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/providers.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ReportsApi(apiClient: apiClient);
});

class ReportsApi {
  ReportsApi({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<void> createReport({required String text}) async {
    await _apiClient.dio.post(
      '/reports',
      data: {
        'text': text,
      },
    );
  }

  Future<List<ReportItem>> listReports() async {
    final res = await _apiClient.dio.get('/reports');
    final data = res.data;
    final itemsAny = (data is Map) ? data['items'] : null;
    if (itemsAny is! List) return const <ReportItem>[];

    return itemsAny
        .whereType<Map>()
        .map((m) => ReportItem.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<void> deleteReport({required String id}) async {
    await _apiClient.dio.delete('/reports/$id');
  }
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String userEmail;

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] is Map)
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};

    final firstName = (user['firstName'] ?? '').toString().trim();
    final lastName = (user['lastName'] ?? '').toString().trim();
    final name = ('$firstName $lastName').trim();

    return ReportItem(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userId: (user['id'] ?? '').toString(),
      userName: name.isEmpty ? '—' : name,
      userEmail: (user['email'] ?? '').toString(),
    );
  }
}
