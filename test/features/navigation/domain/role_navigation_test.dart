import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/navigation/domain/role_navigation.dart';

void main() {
  List<String> labelsFor(UserRole role) => destinationsForRole(
    role,
  ).map((destination) => destination.label).toList();

  test('student can reach learning, submission, registration, and profile', () {
    expect(labelsFor(UserRole.student), [
      'Khóa học',
      'Lịch học',
      'Bài nộp',
      'Đăng ký',
      'Tài khoản',
    ]);
  });

  test('lecturer gets teaching and submission areas', () {
    expect(labelsFor(UserRole.lecturer), [
      'Lớp dạy',
      'Lịch dạy',
      'Bài nộp',
      'Hồ sơ tutor',
      'Tài khoản',
    ]);
  });

  test('coordinator and chairman share manager areas', () {
    final expected = [
      'Khóa học',
      'Buổi học',
      'Đăng ký',
      'Yêu cầu môn',
      'Tài khoản',
    ];

    expect(labelsFor(UserRole.coordinator), expected);
    expect(labelsFor(UserRole.chairman), expected);
  });

  test(
    'admin receives course catalog, CodePulse, and account destinations',
    () {
      expect(labelsFor(UserRole.admin), ['Khóa học', 'CodePulse', 'Tài khoản']);
    },
  );

  test('unknown role has a safe account-only destination', () {
    expect(labelsFor(UserRole.unknown), ['Tài khoản']);
  });
}
