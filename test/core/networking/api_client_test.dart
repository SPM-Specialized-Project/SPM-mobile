import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/core/networking/api_client.dart';
import 'package:spm_mobile/core/security/token_storage.dart';

import '../../support/fake_token_storage.dart';

void main() {
  test('adds the saved bearer token to protected API requests', () async {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(
          FakeTokenStorage(token: 'access-token'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider);
    RequestOptions? capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {},
            ),
          );
        },
      ),
    );

    await dio.get<Map<String, dynamic>>('/api/courses');

    expect(capturedRequest?.headers['Authorization'], 'Bearer access-token');
  });

  test(
    'does not add an authorization header when there is no saved token',
    () async {
      final container = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(FakeTokenStorage())],
      );
      addTearDown(container.dispose);

      final dio = container.read(apiClientProvider);
      RequestOptions? capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {},
              ),
            );
          },
        ),
      );

      await dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: const {'email': 'student@example.com', 'password': 'secret'},
      );

      expect(capturedRequest?.headers.containsKey('Authorization'), isFalse);
    },
  );
}
