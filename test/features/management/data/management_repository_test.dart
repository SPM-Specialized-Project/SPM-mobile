import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/learning/domain/course.dart';
import 'package:spm_mobile/features/management/data/management_models.dart';
import 'package:spm_mobile/features/management/data/management_repository.dart';

const _coordinator = AuthSession(
  accessToken: 'coordinator-token',
  role: UserRole.coordinator,
  user: AuthUser(
    id: 'coordinator-1',
    email: 'coordinator@example.com',
    firstName: 'Course',
    lastName: 'Coordinator',
    picture: null,
  ),
);

void main() {
  test(
    'creates a manager session without client-supplied owner claims',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      RequestOptions? captured;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            final body = options.data as Map<String, dynamic>;
            final item = Map<String, dynamic>.from(
              body['item'] as Map<String, dynamic>,
            )..['id'] = 'session-1';
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {'item': item},
              ),
            );
          },
        ),
      );

      final created = await ManagementRepository(dio).createSession(
        course: const Course(
          id: '13',
          code: 'DSA',
          title: 'Data Structures',
          instructor: 'Lecturer',
          documentCount: 0,
          linkCount: 0,
          assignmentCount: 0,
          students: [],
        ),
        session: _coordinator,
        title: 'Weekly help session',
        description: 'Arrays and lists',
        start: DateTime.utc(2028, 1, 2, 9),
        end: DateTime.utc(2028, 1, 2, 10),
        method: 'online',
        link: 'https://meet.example.com/class',
      );

      final requestBody = captured!.data as Map<String, dynamic>;
      final item = requestBody['item'] as Map<String, dynamic>;
      expect(captured!.method, 'POST');
      expect(captured!.path, '/api/sessions');
      expect(item['courseId'], '13');
      expect(item['start'], '2028-01-02T09:00:00.000Z');
      expect(item.containsKey('ownerRole'), isFalse);
      expect(item.containsKey('ownerEmail'), isFalse);
      expect(created.id, 'session-1');
    },
  );

  test(
    'creates a course request without client-supplied ownership claims',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      RequestOptions? captured;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            final body = options.data as Map<String, dynamic>;
            final item =
                Map<String, dynamic>.from(body['item'] as Map<String, dynamic>)
                  ..['id'] = 'request-1'
                  ..['permissions'] = {'canEdit': true};
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {'item': item},
              ),
            );
          },
        ),
      );

      final created = await ManagementRepository(dio).createCourseRequest(
        session: _coordinator,
        courseName: 'Mobile Engineering',
        courseCode: 'cs499',
        description: 'A course description longer than ten characters.',
        languages: const [ManagementOption(id: 'vi', name: 'Tiếng Việt')],
        sessionTypes: const [
          ManagementOption(id: 'online', name: 'Trực tuyến'),
        ],
      );

      final requestBody = captured!.data as Map<String, dynamic>;
      final item = requestBody['item'] as Map<String, dynamic>;
      expect(captured!.method, 'POST');
      expect(captured!.path, '/api/course-requests');
      expect(item['coordinatorEmail'], _coordinator.user.email);
      expect(item['courseCode'], 'CS499');
      expect(item.containsKey('ownerRole'), isFalse);
      expect(item.containsKey('ownerEmail'), isFalse);
      expect(created.id, 'request-1');
      expect(created.canEdit, isTrue);
    },
  );

  test('updates only course-request review fields', () async {
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
              data: {
                'item': {
                  'id': 'request-1',
                  'courseName': 'Mobile Engineering',
                  'status': 'Rejected',
                  'reasons': 'Thiếu đề cương chi tiết.',
                },
              },
            ),
          );
        },
      ),
    );

    final updated = await ManagementRepository(dio).reviewCourseRequest(
      id: 'request-1',
      status: 'Rejected',
      reason: '  Thiếu đề cương chi tiết.  ',
    );

    expect(captured!.method, 'PATCH');
    expect(captured!.path, '/api/course-requests/request-1');
    expect(captured!.data, {
      'patch': {'status': 'Rejected', 'reasons': 'Thiếu đề cương chi tiết.'},
    });
    expect(updated.status, 'Rejected');
  });
}
