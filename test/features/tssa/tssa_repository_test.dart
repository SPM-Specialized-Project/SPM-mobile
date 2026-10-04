import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/tssa/data/tssa_repository.dart';

void main() {
  test(
    'repository uses canonical versioned API and preserves retry key',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'id': 'record', 'revision': 2},
              ),
            );
          },
        ),
      );
      final repository = TssaRepository(dio);
      await repository.read('requests/r1');
      await repository.write(
        'requests/r1',
        {'expectedRevision': 1},
        patch: true,
        key: 'retry-key-123456',
      );
      await repository.write(
        'requests/r1',
        {'expectedRevision': 1},
        patch: true,
        key: 'retry-key-123456',
      );
      expect(requests.first.path, '/api/v1/requests/r1');
      expect(requests[1].method, 'PATCH');
      expect(requests[1].data, requests[2].data);
      expect(requests[1].data['idempotencyKey'], 'retry-key-123456');
      expect(requests[1].data['expectedRevision'], 1);
    },
  );
  test(
    'keys are unique and errors show the server message without stack details',
    () {
      final keys = List.generate(100, (_) => TssaRepository.newKey());
      expect(keys.toSet().length, 100);
      expect(keys.every((key) => RegExp(r'^[\w-]{32}$').hasMatch(key)), true);
      final options = RequestOptions(path: '/api/v1/requests');
      expect(
        tssaError(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 409,
              data: {'message': 'Tải lại trước khi lưu.'},
            ),
          ),
        ),
        'Tải lại trước khi lưu.',
      );
      expect(tssaError(StateError('secret')), isNot(contains('secret')));
    },
  );
}
