import 'package:dio/dio.dart';

/// Fetches DiceBear schema JSON via backend proxy.
class DicebearSchemaService {
  const DicebearSchemaService({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> fetchAdventurerSchema() async {
    final res = await dio.get('/avatars/dicebear/adventurer.schema.json');
    return Map<String, dynamic>.from(res.data as Map);
  }
}
