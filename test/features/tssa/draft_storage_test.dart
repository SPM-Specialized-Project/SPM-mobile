import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/core/security/draft_storage.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'drafts are isolated by account and form, expire after 24h, and clear keeps token',
    () async {
      final drafts = DraftStorage();
      await drafts.write('alice', 'profile', {
        'values': {'goals': 'Private'},
        'key': 'retry',
      });
      final loaded = (await drafts.read('alice', 'profile'))!;
      expect(loaded['values']['goals'], 'Private');
      expect(
        DateTime.parse(loaded['expiresAt']).difference(DateTime.now()).inHours,
        23,
      );
      expect(await drafts.read('bob', 'profile'), isNull);
      expect(await drafts.read('alice', 'request'), isNull);
      const secure = FlutterSecureStorage();
      await secure.write(key: 'access_token', value: 'token');
      await DraftStorage.clear();
      expect(await drafts.read('alice', 'profile'), isNull);
      expect(await secure.read(key: 'access_token'), 'token');
    },
  );
  test('expired draft is removed and cannot be restored', () async {
    final key = 'tssa_draft_${base64Url.encode(utf8.encode('alice:profile'))}';
    FlutterSecureStorage.setMockInitialValues({
      key: jsonEncode({
        'values': {'goals': 'Expired'},
        'expiresAt': '2020-01-01T00:00:00Z',
      }),
    });
    expect(await DraftStorage().read('alice', 'profile'), isNull);
    expect(await const FlutterSecureStorage().read(key: key), isNull);
  });
}
