import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/student/data/student_registration.dart';
import 'package:spm_mobile/features/student/data/student_repository.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';

const _studentSession = AuthSession(
  accessToken: 'student-token',
  role: UserRole.student,
  user: AuthUser(
    id: 'student-1',
    email: 'student@example.com',
    firstName: 'Student',
    lastName: 'One',
    picture: null,
  ),
);

Map<String, dynamic> _course() => {
  'id': 'course-1',
  'code': 'CS101',
  'title': 'Programming',
  'instructor': 'Lecturer',
  'stats': {'assignments': 1},
  'students': [],
};

Map<String, dynamic> _submission() => {
  'id': 'submission-1',
  'courseId': 'course-1',
  'assignmentId': 'assignment-1',
  'student': {
    'id': 'student-1',
    'name': 'Student One',
    'email': 'student@example.com',
  },
  'assignment': {'id': 'assignment-1', 'title': 'Lab 1'},
  'status': 'submitted',
  'score': null,
  'feedback': '',
  'submittedAt': '2026-10-01T12:00:00Z',
  'fileUrl': 'https://drive.example.com/old',
};

void main() {
  test(
    'submits only the fields student can edit and rejects non-web URLs',
    () async {
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
                data: {'item': _submission()},
              ),
            );
          },
        ),
      );

      final repository = StudentRepository(dio);
      final saved = await repository.submitLink(
        submissionId: 'submission-1',
        fileUri: Uri.parse('https://drive.example.com/my-work'),
      );
      final body = captured!.data as Map<String, dynamic>;

      expect(captured!.method, 'PATCH');
      expect(captured!.path, '/api/submissions/submission-1');
      expect(body.keys, containsAll(['fileUrl', 'submittedAt']));
      expect(body.keys, isNot(contains('score')));
      expect(body.keys, isNot(contains('feedback')));
      expect(saved.id, 'submission-1');

      await expectLater(
        repository.submitLink(
          submissionId: 'submission-1',
          fileUri: Uri.parse('file:///private/report.pdf'),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'creates a student registration using session identity, not owner claims',
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
            )..['id'] = 'registration-1';
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

      final registration = await StudentRepository(dio).createRegistration(
        session: _studentSession,
        course: TutorCourse.fromJson(_course()),
        language: const StudentOption(id: 'vi', name: 'Tiếng Việt'),
        sessionType: const StudentOption(id: 'online', name: 'Trực tuyến'),
        specialRequest: 'Cần hỗ trợ phần cấu trúc dữ liệu.',
      );

      final request = captured!.data as Map<String, dynamic>;
      final item = request['item'] as Map<String, dynamic>;
      expect(captured!.method, 'POST');
      expect(captured!.path, '/api/registrations');
      expect(request['registrationType'], 'student');
      expect(item['Name'], 'Student One');
      expect(item['Email'], 'student@example.com');
      expect(item.containsKey('ownerRole'), isFalse);
      expect(item.containsKey('ownerEmail'), isFalse);
      expect(registration.id, 'registration-1');
    },
  );

  test(
    'uses backend student filter when loading registration history',
    () async {
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

      await StudentRepository(dio).getRegistrations();

      expect(captured!.path, '/api/registrations');
      expect(captured!.queryParameters['registrationType'], 'student');
    },
  );
}
