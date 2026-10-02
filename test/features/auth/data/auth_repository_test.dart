import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_repository.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';

const _loginResponse = <String, dynamic>{
  'accessToken': 'token-demo',
  'role': 'lecturer',
  'user': <String, dynamic>{
    '_id': 'lecturer@gmail.com',
    'email': 'lecturer@gmail.com',
    'firstName': 'Lecturer',
    'lastName': 'User',
    'picture': null,
  },
};

void main() {
  test('posts credentials and parses the login response', () async {
    final dio = Dio();
    RequestOptions? capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _loginResponse,
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    final session = await AuthRepository(
      dio,
    ).login(email: ' lecturer@gmail.com ', password: 'lecturer123');

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, '/api/auth/login');
    expect(capturedRequest?.data, {
      'email': 'lecturer@gmail.com',
      'password': 'lecturer123',
    });
    expect(session.accessToken, 'token-demo');
    expect(session.role, UserRole.lecturer);
  });

  test(
    'restores the session with a stored bearer token and /auth/me data',
    () async {
      final dio = Dio();
      RequestOptions? capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {'role': 'lecturer', 'user': _loginResponse['user']},
              ),
            );
          },
        ),
      );
      addTearDown(() => dio.close(force: true));

      final session = await AuthRepository(
        dio,
      ).restoreSession('persisted-token');

      expect(capturedRequest?.method, 'GET');
      expect(capturedRequest?.path, '/api/auth/me');
      expect(
        capturedRequest?.headers['Authorization'],
        'Bearer persisted-token',
      );
      expect(session.accessToken, 'persisted-token');
      expect(session.role, UserRole.lecturer);
      expect(session.user.email, 'lecturer@gmail.com');
    },
  );
}
