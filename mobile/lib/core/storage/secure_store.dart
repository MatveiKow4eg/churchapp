import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kTokenKey = 'auth_token';
  static const _kBaseUrlKey = 'base_url';

  Future<void> setToken(String token) => _storage.write(key: _kTokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _kTokenKey);

  Future<void> clearToken() => _storage.delete(key: _kTokenKey);

  Future<void> setBaseUrl(String baseUrl) =>
      _storage.write(key: _kBaseUrlKey, value: baseUrl);

  Future<String?> getBaseUrl() => _storage.read(key: _kBaseUrlKey);

  Future<void> clearBaseUrl() => _storage.delete(key: _kBaseUrlKey);
}
