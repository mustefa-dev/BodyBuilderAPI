import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userNameKey = 'user_name';
  static const _userIdKey = 'user_id';

  static Future<void> saveAuth({
    required String token,
    required String fullName,
    required String userId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userNameKey, value: fullName);
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<String?> getUserName() => _storage.read(key: _userNameKey);
  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  static Future<void> clearAll() => _storage.deleteAll();
}
