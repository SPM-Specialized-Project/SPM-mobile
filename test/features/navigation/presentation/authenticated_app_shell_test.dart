import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/app/app.dart';
import 'package:spm_mobile/core/security/token_storage.dart';
import 'package:spm_mobile/features/auth/application/auth_providers.dart';
import 'package:spm_mobile/features/auth/data/auth_repository.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/admin/application/admin_providers.dart';
import 'package:spm_mobile/features/navigation/presentation/authenticated_app_shell.dart';
import 'package:spm_mobile/features/management/application/management_providers.dart';
import 'package:spm_mobile/features/student/application/student_providers.dart';
import 'package:spm_mobile/features/student/data/student_registration.dart';
import 'package:spm_mobile/features/tutor/application/tutor_providers.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_registration.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_session.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_submission.dart';

import '../../../support/fake_token_storage.dart';

const _studentSession = AuthSession(
  accessToken: 'student-token',
  role: UserRole.student,
  user: AuthUser(
    id: 'student-1',
    email: 'student@example.com',
    firstName: 'Student',
    lastName: 'User',
    picture: null,
  ),
);

const _tutorSession = AuthSession(
  accessToken: 'tutor-token',
  role: UserRole.lecturer,
  user: AuthUser(
    id: 'tutor-1',
    email: 'tutor@example.com',
    firstName: 'Tutor',
    lastName: 'User',
    picture: null,
  ),
);

class _SuccessfulAuthRepository extends AuthRepository {
  _SuccessfulAuthRepository(super.dio);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => _studentSession;

  @override
  Future<AuthSession> restoreSession(String accessToken) async {
    return AuthSession(
      accessToken: accessToken,
      user: _studentSession.user,
      role: _studentSession.role,
    );
  }
}

class _RetryableAuthRepository extends _SuccessfulAuthRepository {
  _RetryableAuthRepository(super.dio);

  var _restoreAttempts = 0;

  @override
  Future<AuthSession> restoreSession(String accessToken) async {
    _restoreAttempts++;
    if (_restoreAttempts == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/me'),
        type: DioExceptionType.connectionError,
      );
    }
    return super.restoreSession(accessToken);
  }
}

class _TutorAuthRepository extends AuthRepository {
  _TutorAuthRepository(super.dio);

  @override
  Future<AuthSession> restoreSession(String accessToken) async => _tutorSession;
}

void main() {
  testWidgets('login opens role tabs and logout returns to login', (
    tester,
  ) async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SuccessfulAuthRepository(dio),
          ),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          studentCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          studentSessionsProvider.overrideWith((ref) async => <TutorSession>[]),
          studentSubmissionsProvider.overrideWith(
            (ref) async => <TutorSubmission>[],
          ),
          studentRegistrationsProvider.overrideWith(
            (ref) async => <StudentRegistration>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(find.text('Chào Student!'), findsOneWidget);

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Vai trò do backend cấp'), findsOneWidget);
    expect(find.text('student'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores a saved session when the app starts', (tester) async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SuccessfulAuthRepository(dio),
          ),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'saved-token'),
          ),
          studentCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          studentSessionsProvider.overrideWith((ref) async => <TutorSession>[]),
          studentSubmissionsProvider.overrideWith(
            (ref) async => <TutorSubmission>[],
          ),
          studentRegistrationsProvider.overrideWith(
            (ref) async => <StudentRegistration>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(find.text('HCMUT SSO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student sees read-only sessions, not the tutor create action', (
    tester,
  ) async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SuccessfulAuthRepository(dio),
          ),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'saved-token'),
          ),
          studentCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          studentSessionsProvider.overrideWith((ref) async => <TutorSession>[]),
          studentSubmissionsProvider.overrideWith(
            (ref) async => <TutorSubmission>[],
          ),
          studentRegistrationsProvider.overrideWith(
            (ref) async => <StudentRegistration>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.event_note_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Lịch học'), findsWidgets);
    expect(find.text('Chưa có lịch học'), findsOneWidget);
    expect(find.text('Tạo buổi học'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored lecturer session opens tutor-specific tabs', (
    tester,
  ) async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_TutorAuthRepository(dio)),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(token: 'saved-token'),
          ),
          tutorCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          tutorSessionsProvider.overrideWith((ref) async => <TutorSession>[]),
          tutorSubmissionsProvider.overrideWith(
            (ref) async => <TutorSubmission>[],
          ),
          tutorRegistrationsProvider.overrideWith(
            (ref) async => <TutorRegistration>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Lớp dạy'), findsAtLeastNWidgets(1));
    expect(find.text('Chưa có khóa học được phân công'), findsOneWidget);
    expect(find.text('Hồ sơ tutor'), findsOneWidget);

    await tester.tap(find.text('Lịch dạy'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo buổi học'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the token and lets the user retry session restoration', (
    tester,
  ) async {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    final tokenStorage = FakeTokenStorage(token: 'saved-token');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _RetryableAuthRepository(dio),
          ),
          tokenStorageProvider.overrideWithValue(tokenStorage),
          studentCoursesProvider.overrideWith((ref) async => <TutorCourse>[]),
          studentSessionsProvider.overrideWith((ref) async => <TutorSession>[]),
          studentSubmissionsProvider.overrideWith(
            (ref) async => <TutorSubmission>[],
          ),
          studentRegistrationsProvider.overrideWith(
            (ref) async => <StudentRegistration>[],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Chưa thể xác minh phiên đăng nhập'), findsOneWidget);
    expect(tokenStorage.token, 'saved-token');

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(tokenStorage.token, 'saved-token');
    expect(tester.takeException(), isNull);
  });

  testWidgets('coordinator and chairman get management tabs', (tester) async {
    for (final role in [UserRole.coordinator, UserRole.chairman]) {
      final session = AuthSession(
        accessToken: 'manager-token',
        role: role,
        user: const AuthUser(
          id: 'manager-1',
          email: 'manager@example.com',
          firstName: 'Course',
          lastName: 'Manager',
          picture: null,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            managerCoursesProvider.overrideWith((ref) async => []),
            managerSessionsProvider.overrideWith((ref) async => []),
            managerRegistrationsProvider.overrideWith((ref) async => []),
            courseRequestsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: AuthenticatedAppShell(session: session)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danh mục khóa học'), findsOneWidget);
      expect(find.text('Yêu cầu môn'), findsOneWidget);

      await tester.tap(find.text('Buổi học'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch điều phối'), findsOneWidget);
      expect(find.text('Tạo buổi học'), findsOneWidget);

      await tester.tap(find.text('Yêu cầu môn'));
      await tester.pumpAndSettle();
      expect(find.text('Yêu cầu khóa học'), findsOneWidget);
      expect(find.text('Yêu cầu mở môn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('admin receives CodePulse term and classroom screens', (
    tester,
  ) async {
    final session = AuthSession(
      accessToken: 'admin-token',
      role: UserRole.admin,
      user: const AuthUser(
        id: 'admin-1',
        email: 'admin@example.com',
        firstName: 'System',
        lastName: 'Admin',
        picture: null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managerCoursesProvider.overrideWith((ref) async => []),
          codePulseTermsProvider.overrideWith((ref) async => []),
          codePulseClassroomsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(home: AuthenticatedAppShell(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Danh mục khóa học'), findsOneWidget);
    expect(find.text('CodePulse'), findsOneWidget);
    await tester.tap(find.text('CodePulse'));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý học kỳ CodePulse'), findsOneWidget);
    expect(find.text('Tạo học kỳ'), findsOneWidget);
    expect(find.text('Tạo buổi học'), findsNothing);

    await tester.tap(find.text('Lớp DSA').first);
    await tester.pumpAndSettle();
    expect(find.text('Tạo lớp'), findsOneWidget);
    expect(find.text('Tạo buổi học'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
