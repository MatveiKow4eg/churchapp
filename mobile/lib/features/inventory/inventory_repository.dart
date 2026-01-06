import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import 'models/inventory_item_model.dart';
import 'models/server_inventory_item.dart';

class InventoryRepository {
  InventoryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<InventoryItemModel>> fetchMyInventory() async {
    // Legacy method (kept for compatibility). Step 14.5.3 uses
    // fetchMyServerInventory + catalog mapping.
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/me/inventory',
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final items = data['items'];
      if (items is! List) {
        throw const AppError(
          code: 'invalid_response',
          message: 'Invalid response format',
        );
      }

      return items
          .whereType<Map>()
          .map((e) => InventoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  Future<List<ServerInventoryItem>> fetchMyServerInventory() async {
    try {
      final resp = await _apiClient.dio.get<Map<String, dynamic>>(
        '/me/inventory',
      );

      final data = resp.data;
      if (data == null) {
        throw const AppError(code: 'invalid_response', message: 'Empty response');
      }

      final items = data['items'];
      if (items is! List) {
        throw const AppError(
          code: 'invalid_response',
          message: 'Invalid response format',
        );
      }

      return items
          .whereType<Map>()
          .map((e) =>
              ServerInventoryItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.itemKey.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409 && data is Map) {
        final err = data['error'];
        if (err is Map && (err['code']?.toString() ?? '') == 'NO_CHURCH') {
          throw const AppError(code: 'NO_CHURCH', message: 'NO_CHURCH');
        }
      }

      if (status == 401) {
        throw const AppError(code: 'UNAUTHORIZED', message: 'UNAUTHORIZED');
      }

      throw _mapToRequiredError(e);
    } catch (e) {
      throw _mapToRequiredError(e);
    }
  }

  AppError _mapToRequiredError(Object e) {
    final mapped = ApiClient.mapDioError(e);

    final msg = mapped.message;
    final isBackendMessage = msg != 'Connection timeout' &&
        msg != 'Request send timeout' &&
        msg != 'Response timeout' &&
        msg != 'Bad SSL certificate' &&
        msg != 'Request cancelled' &&
        msg != 'Network connection error' &&
        !msg.startsWith('Server error') &&
        msg != 'Unknown network error';

    if (isBackendMessage) {
      return AppError(code: mapped.code, message: msg);
    }

    return AppError(
      code: mapped.code,
      message: 'Ошибка сети. Проверь адрес сервера.',
    );
  }
}
