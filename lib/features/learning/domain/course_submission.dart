class CourseSubmission {
  const CourseSubmission({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.assignmentTitle,
    required this.assignmentId,
    required this.dueDate,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.score,
    required this.feedback,
    required this.submittedAt,
    required this.fileUrl,
    this.studentId,
    this.termName,
    this.classroomName,
    this.canSubmit = false,
    this.canEdit = false,
    this.canReview = false,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String assignmentTitle;
  final String assignmentId;
  final DateTime? dueDate;
  final String studentName;
  final String studentEmail;
  final String? studentId;
  final String status;
  final double? score;
  final String feedback;
  final DateTime? submittedAt;
  final String? fileUrl;
  final String? termName;
  final String? classroomName;
  final bool canSubmit;
  final bool canEdit;
  final bool canReview;

  factory CourseSubmission.fromJson(Map<String, dynamic> json) {
    final student = _requiredMap(json['student'], 'student');
    final assignment = _requiredMap(json['assignment'], 'assignment');
    final rawScore = json['score'];
    if (rawScore != null && rawScore is! num) {
      throw const FormatException('Submission score must be a number or null.');
    }
    final submittedAtValue = json['submittedAt'];
    final submittedAt = switch (submittedAtValue) {
      null => null,
      String value when DateTime.tryParse(value) != null => DateTime.parse(
        value,
      ),
      _ => throw const FormatException(
        'Submission date must be an ISO date string or null.',
      ),
    };
    final permissions = json['permissions'];
    final permissionMap = permissions is Map<String, dynamic>
        ? permissions
        : const <String, dynamic>{};
    final term = json['term'];
    final classroom = json['classroom'];
    final dueDateValue = assignment['dueDate'];
    return CourseSubmission(
      id: _requiredId(json['id'], 'submission id'),
      courseId: _requiredId(json['courseId'], 'courseId'),
      courseTitle: _optionalString(json['courseTitle']) ?? 'Khóa học',
      assignmentTitle: _optionalString(assignment['title']) ?? 'Bài tập',
      assignmentId: _optionalId(assignment['id']) ?? '',
      dueDate: dueDateValue is String ? DateTime.tryParse(dueDateValue) : null,
      studentName: _requiredString(student, 'name'),
      studentEmail: _requiredString(student, 'email'),
      studentId: _optionalId(student['id']) ?? _optionalId(student['_id']),
      status: _optionalString(json['status']) ?? 'submitted',
      score: (rawScore as num?)?.toDouble(),
      feedback: _optionalString(json['feedback']) ?? '',
      submittedAt: submittedAt,
      fileUrl: _optionalString(json['fileUrl']),
      termName: term is Map<String, dynamic>
          ? _optionalString(term['name'])
          : null,
      classroomName: classroom is Map<String, dynamic>
          ? _optionalString(classroom['name'])
          : null,
      canSubmit: permissionMap['canSubmit'] == true,
      canEdit: permissionMap['canEdit'] == true,
      canReview: permissionMap['canReview'] == true,
    );
  }
}

String? _optionalId(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return value.toString();
  return null;
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Submission $field must be an object.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value != null && value.isNotEmpty) return value;
  throw FormatException('Submission field "$key" must be a non-empty string.');
}

String _requiredId(Object? value, String key) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is num) return value.toString();
  throw FormatException('Submission field "$key" must be a string or number.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Submission fields must be strings.');
}
