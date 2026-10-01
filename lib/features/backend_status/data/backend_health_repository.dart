import 'package:dio/dio.dart';

import 'backend_health.dart';

class BackendHealthRepository {
  const BackendHealthRepository(this._dio);

  final Dio _dio;

  Future<BackendHealth> check() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/health');
    final body = response.data;

    if (body == null) {
      throw const FormatException('Backend returned an empty health response.');
    }

    final health = BackendHealth.fromJson(body);
    if (!health.ok) {
      throw StateError('Backend health check returned ok=false.');
    }

    return health;
  }
}
