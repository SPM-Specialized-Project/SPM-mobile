import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/core/networking/api_client.dart';
import 'package:spm_mobile/core/security/draft_storage.dart';
import 'package:spm_mobile/core/security/session_events.dart';
import 'package:spm_mobile/core/security/token_storage.dart';
import '../../support/fake_token_storage.dart';

class StatusAdapter implements HttpClientAdapter {
  StatusAdapter(this.status, {this.code, this.beforeResponse});
  final int status;
  final String? code;
  final Future<void> Function()? beforeResponse;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await beforeResponse?.call();
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'Denied'}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final entry in [(401, null), (403, 'ACCOUNT_LOCKED')]) {
    test(
      'S01 ${entry.$1}/${entry.$2} expires current token and removes drafts',
      () async {
        final tokens = FakeTokenStorage(token: 'current');
        final container = ProviderContainer(
          overrides: [tokenStorageProvider.overrideWithValue(tokens)],
        );
        addTearDown(container.dispose);
        await DraftStorage().write('alice', 'profile', {
          'values': {'goals': 'private'},
        });
        final dio = container.read(apiClientProvider);
        dio.httpClientAdapter = StatusAdapter(entry.$1, code: entry.$2);
        await expectLater(
          dio.get('/api/v1/learners'),
          throwsA(isA<DioException>()),
        );
        expect(await tokens.readAccessToken(), isNull);
        expect(await DraftStorage().read('alice', 'profile'), isNull);
        expect(container.read(sessionExpiryProvider), 1);
        expect(container.read(apiSessionEpochProvider), 1);
      },
    );
  }
  test('S02 login failure preserves current token and draft', () async {
    final tokens = FakeTokenStorage(token: 'current');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokens)],
    );
    addTearDown(container.dispose);
    await DraftStorage().write('alice', 'profile', {
      'values': {'goals': 'private'},
    });
    final dio = container.read(apiClientProvider);
    dio.httpClientAdapter = StatusAdapter(401);
    await expectLater(
      dio.post('/api/auth/login', data: {'email': 'bad', 'password': 'bad'}),
      throwsA(isA<DioException>()),
    );
    expect(await tokens.readAccessToken(), 'current');
    expect(await DraftStorage().read('alice', 'profile'), isNotNull);
    expect(container.read(sessionExpiryProvider), 0);
  });
  test(
    'S03 late unauthorized old request does not expire a newer login',
    () async {
      final tokens = FakeTokenStorage(token: 'old');
      final container = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(tokens)],
      );
      addTearDown(container.dispose);
      final dio = container.read(apiClientProvider);
      dio.httpClientAdapter = StatusAdapter(
        401,
        beforeResponse: () => tokens.saveAccessToken('new'),
      );
      await expectLater(dio.get('/api/v1/me'), throwsA(isA<DioException>()));
      expect(await tokens.readAccessToken(), 'new');
      expect(container.read(sessionExpiryProvider), 0);
    },
  );
  test(
    'S04 scoped denial clears sensitive drafts but retains valid session',
    () async {
      final tokens = FakeTokenStorage(token: 'current');
      final container = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(tokens)],
      );
      addTearDown(container.dispose);
      await DraftStorage().write('alice', 'profile', {
        'values': {'goals': 'private'},
      });
      final dio = container.read(apiClientProvider);
      dio.httpClientAdapter = StatusAdapter(403, code: 'CONSENT_REQUIRED');
      await expectLater(
        dio.get('/api/v1/learners/private/profile'),
        throwsA(isA<DioException>()),
      );
      expect(await DraftStorage().read('alice', 'profile'), isNull);
      expect(await tokens.readAccessToken(), 'current');
      expect(container.read(sessionExpiryProvider), 0);
    },
  );
}
