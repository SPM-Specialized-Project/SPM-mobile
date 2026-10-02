import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/tutor/data/tutor_repository.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';

const _session = AuthSession(
  accessToken: 'token',
  role: UserRole.lecturer,
  user: AuthUser(
    id: 'tutor@example.com',
    email: 'tutor@example.com',
    firstName: 'Tutor',
    lastName: 'User',
    picture: null,
  ),
);

Map<String, dynamic> _course(String id) => {
  'id': id,
  'code': 'CS$id',
  'title': 'Course $id',
  'instructor': 'Tutor User',
  'stats': {'documents': 0, 'links': 0, 'assignments': 1},
  'students': [],
};

Map<String, dynamic> _submission(String id) => {
  'id': id,
  'courseId': '2',
  'assignmentId': 'assignment-2',
  'student': {
    'id': 'student-1',
    'name': 'Student One',
    'email': 'student@example.com',
  },
  'assignment': {'id': 'assignment-2', 'title': 'Lab 2', 'dueDate': ''},
  'status': 'submitted',
  'score': null,
  'feedback': '',
  'submittedAt': '2026-10-01T12:00:00Z',
  'fileUrl': null,
};

void main() {
  test('gets only backend-assigned courses without sending a client role', () async {
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
                'items': [_course('1')],
              },
            ),
          );
        },
      ),
    );

    final courses = await TutorRepository(dio).getCourses();

    expect(captured?.path, '/api/courses');
    expect(captured?.queryParameters, isEmpty);
    expect(courses.single.id, '1');
  });

  test('continues loading course submissions when another course has none', () async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/api/courses') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [_course('1'), _course('2')],
                },
              ),
            );
            return;
          }
          if (options.path == '/api/courses/1/submissions') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [_submission('submission-2')],
              },
            ),
          );
        },
      ),
    );

    final submissions = await TutorRepository(dio).getSubmissions();

    expect(submissions, hasLength(1));
    expect(submissions.single.courseTitle, 'Course 2');
    expect(submissions.single.assignmentTitle, 'Lab 2');
  });

  test('posts session creation without trusting client-supplied ownership', () async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          final item = (options.data as Map<String, dynamic>)['item']
              as Map<String, dynamic>;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'item': {
                  ...item,
                  'id': 'session-created',
                  'ownerRole': 'lecturer',
                  'ownerEmail': 'tutor@example.com',
                },
              },
            ),
          );
        },
      ),
    );

    final created = await TutorRepository(dio).createSession(
      course: TutorCourse.fromJson(_course('2')),
      session: _session,
      title: 'Tutor buổi 1',
      description: 'Giải đáp bài tập',
      start: DateTime.utc(2026, 10, 10, 2),
      end: DateTime.utc(2026, 10, 10, 3),
      method: 'online',
      link: 'https://meet.example.com/room',
    );

    final requestBody = captured?.data as Map<String, dynamic>;
    final item = requestBody['item'] as Map<String, dynamic>;
    expect(captured?.method, 'POST');
    expect(captured?.path, '/api/sessions');
    expect(item.containsKey('ownerRole'), isFalse);
    expect(item.containsKey('ownerEmail'), isFalse);
    expect(created.id, 'session-created');
  });

  test('queries tutor-owned registrations using the backend filter', () async {
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
              data: const {'items': []},
            ),
          );
        },
      ),
    );

    await TutorRepository(dio).getRegistrations();

    expect(captured?.path, '/api/registrations');
    expect(captured?.queryParameters['registrationType'], 'tutor');
  });
}
