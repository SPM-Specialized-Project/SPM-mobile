enum UserRole {
  student,
  lecturer,
  coordinator,
  chairman,
  admin,
  tssaLearner,
  tssaGuardian,
  tssaTutor,
  unknown;

  static UserRole fromApi(String value) {
    switch (value.trim().toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'lecturer':
      case 'tutor':
        return UserRole.lecturer;
      case 'coordinator':
        return UserRole.coordinator;
      case 'chairman':
        return UserRole.chairman;
      case 'admin':
        return UserRole.admin;
      case 'tssa_learner':
        return UserRole.tssaLearner;
      case 'tssa_guardian':
        return UserRole.tssaGuardian;
      case 'tssa_tutor':
        return UserRole.tssaTutor;
      default:
        return UserRole.unknown;
    }
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.picture,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? picture;

  String get name => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final pictureValue = json['picture'];
    if (pictureValue != null && pictureValue is! String) {
      throw const FormatException('User picture must be a string or null.');
    }

    return AuthUser(
      id: _requiredString(json, '_id'),
      email: _requiredString(json, 'email'),
      firstName: _requiredString(json, 'firstName'),
      lastName: _requiredString(json, 'lastName'),
      picture: pictureValue as String?,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    required this.role,
  });

  final String accessToken;
  final AuthUser user;
  final UserRole role;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokenValue = json['accessToken'];
    final roleValue = json['role'];
    final userValue = json['user'];

    if (tokenValue is! String || tokenValue.trim().isEmpty) {
      throw const FormatException(
        'Login response must contain a non-empty accessToken.',
      );
    }

    if (roleValue is! String || roleValue.trim().isEmpty) {
      throw const FormatException(
        'Login response must contain a non-empty role.',
      );
    }

    if (userValue is! Map<String, dynamic>) {
      throw const FormatException('Login response must contain a user object.');
    }

    return AuthSession(
      accessToken: tokenValue,
      user: AuthUser.fromJson(userValue),
      role: UserRole.fromApi(roleValue),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw FormatException('User field "$key" must be a non-empty string.');
}
