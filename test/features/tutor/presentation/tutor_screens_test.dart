import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/app/theme/app_theme.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/tutor/application/tutor_providers.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course_workspace.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_course_detail_screen.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_courses_screen.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_registrations_screen.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_sessions_screen.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_submissions_screen.dart';

const _session = AuthSession(
  accessToken: 'tutor-token',
  role: UserRole.lecturer,
  user: AuthUser(
    id: 'tutor-1',
    email: 'tutor@example.com',
    firstName: 'Tutor',
    lastName: 'One',
    picture: null,
  ),
);

final _course = TutorCourse.fromJson({
  'id': '1',
  'code': 'CS101',
  'title': 'Lập trình Flutter',
  'instructor': 'Tutor One',
  'students': [
    {'id': 'student-1', 'name': 'Student One', 'email': 'student@example.com'},
  ],
  'stats': {'documents': 2, 'links': 1, 'assignments': 3},
});

final _courseDetail = TutorCourseDetail.fromJson({
  'course': {
    'id': '1',
    'code': 'CS101',
    'title': 'Lập trình Flutter',
    'instructor': 'Tutor One',
    'students': [
      {
        'id': 'student-1',
        'name': 'Student One',
        'email': 'student@example.com',
      },
    ],
  },
  'detail': {
    'content': [
      {'id': 'section-1', 'type': 'material', 'title': 'Widget cơ bản'},
    ],
  },
});

Widget _testApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('tutor can open an assigned course and switch to its roster', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorCoursesProvider.overrideWith((ref) async => [_course]),
          tutorCourseDetailProvider.overrideWith(
            (ref, courseId) async => _courseDetail,
          ),
          tutorCourseRosterProvider.overrideWith(
            (ref, id) async => const CourseRoster(
              members: [
                CourseMember(
                  id: 'member-1',
                  name: 'Student One',
                  email: 'student@example.com',
                  status: 'ACTIVE',
                  canEdit: false,
                ),
              ],
              availableStudents: [],
              canCreate: false,
            ),
          ),
        ],
        child: _testApp(child: TutorCoursesScreen(session: _session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(find.text('Lập trình Flutter'), findsOneWidget);
    expect(find.text('1 sinh viên'), findsOneWidget);

    await tester.tap(find.text('Lập trình Flutter'));
    await tester.pumpAndSettle();
    expect(find.byType(TutorCourseDetailScreen), findsOneWidget);
    expect(find.text('Widget cơ bản'), findsOneWidget);

    await tester.tap(find.text('Danh sách lớp'));
    await tester.pumpAndSettle();
    expect(find.text('Student One'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutor screens present clear empty states', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          tutorSessionsProvider.overrideWith((ref) async => []),
          tutorSubmissionsProvider.overrideWith((ref) async => []),
          tutorRegistrationsProvider.overrideWith((ref) async => []),
        ],
        child: _testApp(child: TutorSessionsScreen(session: _session)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có buổi học'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          tutorSessionsProvider.overrideWith((ref) async => []),
          tutorSubmissionsProvider.overrideWith((ref) async => []),
          tutorRegistrationsProvider.overrideWith((ref) async => []),
        ],
        child: _testApp(child: const TutorSubmissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có bài nộp'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          tutorSessionsProvider.overrideWith((ref) async => []),
          tutorSubmissionsProvider.overrideWith((ref) async => []),
          tutorRegistrationsProvider.overrideWith((ref) async => []),
        ],
        child: _testApp(child: TutorRegistrationsScreen(session: _session)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có hồ sơ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
