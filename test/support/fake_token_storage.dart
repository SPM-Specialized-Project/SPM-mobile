import 'package:spm_mobile/core/security/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.token});

  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String value) async {
    token = value;
  }

  @override
  Future<void> clearAccessToken() async {
    token = null;
  }
}
