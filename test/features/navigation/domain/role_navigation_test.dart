import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';
import 'package:spm_mobile/features/navigation/domain/role_navigation.dart';

void main() {
  List<String> labelsFor(UserRole role) => destinationsForRole(
    role,
  ).map((destination) => destination.label).toList();

  test('all roles keep the same primary navigation positions', () {
    const expected = ['Khóa học', 'Lịch', 'Thư viện', 'Thêm'];

    expect(labelsFor(UserRole.student), expected);
    expect(labelsFor(UserRole.lecturer), expected);
    expect(labelsFor(UserRole.coordinator), expected);
    expect(labelsFor(UserRole.chairman), expected);
    expect(labelsFor(UserRole.admin), expected);
    expect(labelsFor(UserRole.unknown), expected);
  });
}
