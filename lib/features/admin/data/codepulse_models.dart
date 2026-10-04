class CodePulseTerm {
  const CodePulseTerm({
    required this.id,
    required this.courseId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.resetDate,
    required this.status,
  });

  final String id;
  final String courseId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime resetDate;
  final String status;

  factory CodePulseTerm.fromJson(Map<String, dynamic> json) => CodePulseTerm(
    id: _requiredString(json, 'id'),
    courseId: _requiredString(json, 'courseId'),
    name: _requiredString(json, 'name'),
    startDate: _requiredDate(json, 'startDate'),
    endDate: _requiredDate(json, 'endDate'),
    resetDate: _requiredDate(json, 'resetDate'),
    status: _requiredString(json, 'status'),
  );
}

class CodePulseClassroom {
  const CodePulseClassroom({
    required this.id,
    required this.courseId,
    required this.termId,
    required this.name,
    required this.description,
    required this.status,
    required this.lecturerEmail,
    required this.termName,
  });

  final String id;
  final String courseId;
  final String termId;
  final String name;
  final String description;
  final String status;
  final String? lecturerEmail;
  final String? termName;

  factory CodePulseClassroom.fromJson(Map<String, dynamic> json) {
    final rawTerm = json['term'];
    final term = rawTerm is Map<String, dynamic> ? rawTerm : null;
    return CodePulseClassroom(
      id: _requiredString(json, 'id'),
      courseId: _requiredString(json, 'courseId'),
      termId: _requiredString(json, 'termId'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json['description']) ?? '',
      status: _requiredString(json, 'status'),
      lecturerEmail: _optionalString(json['lecturerEmail']),
      termName: term == null ? null : _optionalString(term['name']),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw FormatException('CodePulse field "$key" must be a non-empty string.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) {
    return value.trim();
  }
  throw const FormatException('CodePulse text fields must be strings.');
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is! String) {
    throw FormatException('CodePulse $key must be a date string.');
  }
  final date = DateTime.tryParse(raw);
  if (date == null) {
    throw FormatException('CodePulse $key is not a valid date.');
  }
  return date;
}
