import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps encrypted, secure storage of the JWT auth token.
///
/// Nothing else in the app should touch `SharedPreferences`, plain files or
/// in-memory globals for the token: every read/write goes through here so
/// the storage mechanism can be swapped or mocked in one place.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
