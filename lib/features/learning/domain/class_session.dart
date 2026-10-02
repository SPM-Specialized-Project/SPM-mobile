class ClassSession {
  const ClassSession({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.method,
    required this.status,
    required this.link,
    required this.location,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String method;
  final String status;
  final String? link;
  final String? location;

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: _requiredString(json, 'id'),
    courseId: _requiredId(json['courseId'], 'courseId'),
    courseTitle: _optionalString(json['courseTitle']) ?? 'Khóa học',
    title: _requiredString(json, 'title'),
    description: _optionalString(json['desc']) ?? '',
    start: _requiredDate(json, 'start'),
    end: _requiredDate(json, 'end'),
    method: _optionalString(json['method']) ?? 'offline',
    status: _optionalString(json['status']) ?? 'scheduled',
    link: _optionalString(json['link']),
    location: _optionalString(json['location']),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value != null && value.isNotEmpty) return value;
  throw FormatException('Session field "$key" must be a non-empty string.');
}

String _requiredId(Object? value, String key) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is num) return value.toString();
  throw FormatException('Session field "$key" must be a string or number.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Session fields must be strings.');
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Session field "$key" must be an ISO date string.');
  }
  final date = DateTime.tryParse(value);
  if (date == null) {
    throw FormatException('Session field "$key" is not a valid date.');
  }
  return date;
}
