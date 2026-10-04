import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';

typedef TssaData = Map<String, dynamic>;

class TssaRepository {
  TssaRepository(this._dio);
  final Dio _dio;
  static String newKey() => base64Url
      .encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');
  Future<TssaData> read(String path) async =>
      (await _dio.get<TssaData>('/api/v1/$path')).data!;
  Future<TssaData> write(
    String path,
    TssaData data, {
    bool patch = false,
    String? key,
  }) async {
    final body = {...data, 'idempotencyKey': key ?? newKey()};
    final response = patch
        ? await _dio.patch<TssaData>('/api/v1/$path', data: body)
        : await _dio.post<TssaData>('/api/v1/$path', data: body);
    return response.data!;
  }
}

final tssaRepositoryProvider = Provider<TssaRepository>(
  (ref) => TssaRepository(ref.watch(apiClientProvider)),
);
final tssaIdentityProvider = FutureProvider.autoDispose<TssaData>(
  (ref) => ref.watch(tssaRepositoryProvider).read('me'),
);
final tssaPreferencesProvider = FutureProvider.autoDispose<TssaData>(
  (ref) => ref.watch(tssaRepositoryProvider).read('preferences'),
);
String tssaError(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return 'Chưa nhận được xác nhận từ máy chủ. Kiểm tra kết nối rồi thử lại.';
  }
  return 'Không thể hoàn tất thao tác. Hãy tải lại và thử lại.';
}

List<TssaData> tssaItems(TssaData data) => ((data['items'] as List?) ?? [])
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();
