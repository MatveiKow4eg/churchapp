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

  // Generic helpers for local flags (e.g. avatar setup stub)
  Future<void> setBool(String key, bool value) =>
      _storage.write(key: key, value: value ? '1' : '0');

  Future<bool?> getBool(String key) async {
    final v = await _storage.read(key: key);
    if (v == null) return null;
    if (v == '1' || v.toLowerCase() == 'true') return true;
    if (v == '0' || v.toLowerCase() == 'false') return false;
    return null;
  }

  Future<void> delete(String key) => _storage.delete(key: key);
}
