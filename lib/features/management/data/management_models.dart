import '../../../features/learning/domain/class_session.dart';
import '../../../features/learning/domain/course.dart';

class ManagementOption {
  const ManagementOption({required this.id, required this.name});

  final String id;
  final String name;

  factory ManagementOption.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Option phải là một object.');
    }
    final id = value['id'];
    final name = value['name'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Option thiếu id hoặc name.');
    }
    return ManagementOption(id: id.trim(), name: name.trim());
  }
}

class CourseRequest {
  const CourseRequest({
    required this.id,
    required this.coordinatorName,
    required this.coordinatorEmail,
    required this.courseName,
    required this.courseCode,
    required this.description,
    required this.status,
    required this.reasons,
    required this.createdAt,
    required this.languages,
    required this.sessionTypes,
    required this.permissions,
  });

  final String id;
  final String coordinatorName;
  final String coordinatorEmail;
  final String courseName;
  final String courseCode;
  final String description;
  final String status;
  final String reasons;
  final DateTime? createdAt;
  final List<ManagementOption> languages;
  final List<ManagementOption> sessionTypes;
  final Map<String, dynamic> permissions;

  bool get canEdit => permissions['canEdit'] == true;

  factory CourseRequest.fromJson(Map<String, dynamic> json) => CourseRequest(
    id: _requiredString(json, 'id'),
    coordinatorName:
        _optionalString(json['coordinatorName']) ?? 'Điều phối viên',
    coordinatorEmail: _optionalString(json['coordinatorEmail']) ?? '',
    courseName: _requiredString(json, 'courseName'),
    courseCode: _optionalString(json['courseCode']) ?? '',
    description: _optionalString(json['description']) ?? '',
    status: _optionalString(json['status']) ?? 'Pending',
    reasons: _optionalString(json['reasons']) ?? '',
    createdAt: _optionalDate(json['createdAt']),
    languages: _readOptions(json['languages'], 'languages'),
    sessionTypes: _readOptions(json['sessionTypes'], 'sessionTypes'),
    permissions: _optionalMap(json['permissions']),
  );
}

class ManagedRegistration {
  const ManagedRegistration({
    required this.id,
    required this.type,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.summary,
    required this.specialRequest,
    required this.declineReason,
    required this.permissions,
  });

  final String id;
  final String type;
  final String name;
  final String email;
  final String status;
  final DateTime? createdAt;
  final String summary;
  final String specialRequest;
  final String? declineReason;
  final Map<String, dynamic> permissions;

  bool get canEdit => permissions['canEdit'] == true;

  factory ManagedRegistration.fromJson(Map<String, dynamic> json) {
    final subjects = _readOptions(json['subjects'], 'subjects');
    final requestedCourses = _readOptions(json['courses'], 'courses');
    final topics = subjects.isNotEmpty ? subjects : requestedCourses;
    final type = _optionalString(json['registrationType']) ?? 'unknown';
    return ManagedRegistration(
      id: _requiredString(json, 'id'),
      type: type,
      name:
          _optionalString(json['Name']) ??
          _optionalString(json['name']) ??
          'Chưa có tên',
      email:
          _optionalString(json['Email']) ??
          _optionalString(json['email']) ??
          '',
      status: _optionalString(json['status']) ?? 'Pending',
      createdAt: _optionalDate(json['createdAt']),
      summary: topics.map((item) => item.name).join(', '),
      specialRequest: _optionalString(json['specialRequest']) ?? '',
      declineReason: _optionalString(json['declineReason']),
      permissions: _optionalMap(json['permissions']),
    );
  }
}

List<ManagementOption> _readOptions(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$field phải là danh sách.');
  return [for (final item in value) ManagementOption.fromJson(item)];
}

Map<String, dynamic> _optionalMap(Object? value) {
  if (value == null) return const {};
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Permissions phải là object.');
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = _optionalString(json[field]);
  if (value != null && value.isNotEmpty) return value;
  throw FormatException('$field phải là chuỗi không rỗng.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Giá trị văn bản không hợp lệ.');
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  throw const FormatException('Ngày phải là chuỗi ISO hoặc null.');
}

// These imports are intentionally referenced here so consumers can import the
// management contracts from one module without creating role-specific copies.
typedef ManagedCourse = Course;
typedef ManagedSession = ClassSession;
