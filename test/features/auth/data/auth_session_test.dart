import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/auth/data/auth_session.dart';

const _studentLoginResponse = <String, dynamic>{
  'accessToken': 'token-demo',
  'role': 'student',
  'user': <String, dynamic>{
    '_id': 'student@gmail.com',
    'email': 'student@gmail.com',
    'firstName': 'Student',
    'lastName': 'User',
    'picture': null,
  },
};

void main() {
  group('AuthSession.fromJson', () {
    test('maps the backend login response, including a null picture', () {
      final session = AuthSession.fromJson(_studentLoginResponse);

      expect(session.accessToken, 'token-demo');
      expect(session.role, UserRole.student);
      expect(session.user.id, 'student@gmail.com');
      expect(session.user.email, 'student@gmail.com');
      expect(session.user.firstName, 'Student');
      expect(session.user.lastName, 'User');
      expect(session.user.picture, isNull);
      expect(session.user.name, 'Student User');
    });

    test('maps an unrecognized role to unknown', () {
      final response = <String, dynamic>{
        ..._studentLoginResponse,
        'role': 'new-role',
      };

      final session = AuthSession.fromJson(response);

      expect(session.role, UserRole.unknown);
    });

    test('maps the legacy tutor role to lecturer', () {
      expect(UserRole.fromApi(' tutor '), UserRole.lecturer);
    });

    test('rejects a missing access token with FormatException', () {
      final response = Map<String, dynamic>.from(_studentLoginResponse)
        ..remove('accessToken');

      expect(
        () => AuthSession.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing user object with FormatException', () {
      final response = Map<String, dynamic>.from(_studentLoginResponse)
        ..remove('user');

      expect(
        () => AuthSession.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
