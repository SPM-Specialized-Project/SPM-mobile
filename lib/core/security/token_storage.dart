import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> saveAccessToken(String token);

  Future<void> clearAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'spm_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> saveAccessToken(String token) {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'Access token cannot be empty.',
      );
    }
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> clearAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(FlutterSecureStorage());
});
