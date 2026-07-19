import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Menyimpan token login secara aman di perangkat (Keychain di iOS,
/// EncryptedSharedPreferences di Android) — bukan sekadar SharedPreferences
/// biasa, supaya token tidak mudah dibaca aplikasi/proses lain.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
