class StudentOption {
  const StudentOption({required this.id, required this.name});

  final String id;
  final String name;

  factory StudentOption.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Registration option must be an object.');
    }
    final id = value['id'];
    final name = value['name'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Registration option needs id and name.');
    }
    return StudentOption(id: id.trim(), name: name.trim());
  }
}

class StudentRegistration {
  const StudentRegistration({
    required this.id,
    required this.name,
    required this.email,
    required this.subjects,
    required this.languages,
    required this.sessionTypes,
    required this.locations,
    required this.specialRequest,
    required this.status,
    required this.createdAt,
    required this.declineReason,
  });

  final String id;
  final String name;
  final String email;
  final List<StudentOption> subjects;
  final List<StudentOption> languages;
  final List<StudentOption> sessionTypes;
  final List<StudentOption> locations;
  final String specialRequest;
  final String status;
  final DateTime? createdAt;
  final String? declineReason;

  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    return StudentRegistration(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'Name'),
      email: _requiredString(json, 'Email'),
      subjects: _readOptions(json['subjects'], 'subjects'),
      languages: _readOptions(json['languages'], 'languages'),
      sessionTypes: _readOptions(json['sessionTypes'], 'sessionTypes'),
      locations: _readOptions(json['locations'], 'locations'),
      specialRequest: _optionalString(json['specialRequest']) ?? '',
      status: _optionalString(json['status']) ?? 'Pending',
      createdAt: _optionalDate(json['createdAt']),
      declineReason: _optionalString(json['declineReason']),
    );
  }
}

List<StudentOption> _readOptions(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) {
    throw FormatException('Registration $field must be a list.');
  }
  return [for (final option in value) StudentOption.fromJson(option)];
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException(
    'Registration field "$field" must be a non-empty string.',
  );
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Registration optional fields must be strings.');
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  throw const FormatException('Registration date must be a string or null.');
}
