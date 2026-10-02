import 'package:dio/dio.dart';

import 'auth_session.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email.trim(), 'password': password},
    );

    final body = response.data;
    if (body == null) {
      throw const FormatException('Backend returned an empty login response.');
    }

    return AuthSession.fromJson(body);
  }

  Future<AuthSession> restoreSession(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    final body = response.data;
    if (body == null) {
      throw const FormatException(
        'Backend returned an empty session response.',
      );
    }

    return AuthSession.fromJson({...body, 'accessToken': accessToken});
  }
}
