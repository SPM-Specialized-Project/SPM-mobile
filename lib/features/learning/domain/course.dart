class CourseStudent {
  const CourseStudent({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory CourseStudent.fromJson(Map<String, dynamic> json) {
    final email = _requiredString(json, 'email');
    return CourseStudent(
      id: _optionalString(json['id']) ?? email,
      name: _requiredString(json, 'name'),
      email: email,
    );
  }
}

class Course {
  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.instructor,
    required this.documentCount,
    required this.linkCount,
    required this.assignmentCount,
    required this.students,
  });

  final String id;
  final String code;
  final String title;
  final String instructor;
  final int documentCount;
  final int linkCount;
  final int assignmentCount;
  final List<CourseStudent> students;

  factory Course.fromJson(Map<String, dynamic> json) {
    final stats = _optionalMap(json['stats']);
    final rawStudents = json['students'];
    if (rawStudents != null && rawStudents is! List) {
      throw const FormatException('Course students must be a list.');
    }
    return Course(
      id: _requiredId(json['id'], 'course id'),
      code: _optionalString(json['code']) ?? 'Mã môn chưa có',
      title: _requiredString(json, 'title'),
      instructor: _optionalString(json['instructor']) ?? 'Chưa phân công',
      documentCount: _optionalInt(stats?['documents']) ?? 0,
      linkCount: _optionalInt(stats?['links']) ?? 0,
      assignmentCount: _optionalInt(stats?['assignments']) ?? 0,
      students: [
        for (final student in rawStudents as List<dynamic>? ?? const [])
          CourseStudent.fromJson(_requiredMap(student, 'course student')),
      ],
    );
  }
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.type,
    required this.title,
  });

  final String id;
  final String type;
  final String title;

  factory CourseSection.fromJson(Map<String, dynamic> json) => CourseSection(
    id: _requiredId(json['id'], 'content id'),
    type: _optionalString(json['type']) ?? 'other',
    title: _optionalString(json['title']) ?? 'Nội dung khóa học',
  );
}

class CourseDetail {
  const CourseDetail({required this.course, required this.sections});

  final Course course;
  final List<CourseSection> sections;

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final course = _requiredMap(json['course'], 'course');
    final detail = _requiredMap(json['detail'], 'course detail');
    final rawSections = detail['content'];
    if (rawSections is! List) {
      throw const FormatException('Course detail content must be a list.');
    }
    return CourseDetail(
      course: Course.fromJson(course),
      sections: [
        for (final section in rawSections)
          CourseSection.fromJson(_requiredMap(section, 'course section')),
      ],
    );
  }
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$field must be an object.');
}

Map<String, dynamic>? _optionalMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Expected an object.');
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = _optionalString(json[field]);
  if (value != null && value.isNotEmpty) return value;
  throw FormatException('Course field "$field" must be a non-empty string.');
}

String _requiredId(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is num) return value.toString();
  throw FormatException('$field must be a non-empty string or number.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Expected a string.');
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const FormatException('Expected a number.');
}
