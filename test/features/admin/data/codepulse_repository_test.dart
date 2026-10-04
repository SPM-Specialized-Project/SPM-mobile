import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/admin/data/codepulse_repository.dart';

void main() {
  test('creates terms scoped to the backend DSA course', () async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    RequestOptions? captured;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          final body = options.data as Map<String, dynamic>;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'item': {
                  'id': 'term-new',
                  'courseId': '13',
                  ...body,
                  'status': 'DRAFT',
                },
              },
            ),
          );
        },
      ),
    );

    final term = await CodePulseRepository(dio).createTerm(
      name: 'Semester 2028',
      startDate: DateTime(2028, 1, 1),
      endDate: DateTime(2028, 6, 1),
      resetDate: DateTime(2028, 6, 2),
    );

    expect(captured!.path, '/api/codepulse/terms');
    expect(captured!.queryParameters['courseId'], '13');
    expect(captured!.data['name'], 'Semester 2028');
    expect(captured!.data.containsKey('courseId'), isFalse);
    expect(term.id, 'term-new');
    expect(term.status, 'DRAFT');
  });

  test('classroom deletion targets the scoped resource route', () async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    RequestOptions? captured;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {'deleted': true},
            ),
          );
        },
      ),
    );

    await CodePulseRepository(dio).deleteClassroom('class-42');

    expect(captured!.method, 'DELETE');
    expect(captured!.path, '/api/codepulse/classrooms/class-42');
    expect(captured!.queryParameters['courseId'], '13');
  });
}
