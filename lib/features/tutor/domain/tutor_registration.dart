class TutorOption {
  const TutorOption({required this.id, required this.name});

  final String id;
  final String name;

  factory TutorOption.fromJson(Map<String, dynamic> json) {
    return TutorOption(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
    );
  }

  Map<String, String> toJson() => {'id': id, 'name': name};
}

class TutorRegistration {
  const TutorRegistration({
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
  });

  final String id;
  final String name;
  final String email;
  final List<TutorOption> subjects;
  final List<TutorOption> languages;
  final List<TutorOption> sessionTypes;
  final List<TutorOption> locations;
  final String specialRequest;
  final String status;
  final DateTime? createdAt;

  factory TutorRegistration.fromJson(Map<String, dynamic> json) {
    return TutorRegistration(
      id: _requiredId(json['id']),
      name: _requiredString(json, 'Name'),
      email: _requiredString(json, 'Email'),
      subjects: _readOptions(json['subjects'], 'subjects'),
      languages: _readOptions(json['languages'], 'languages'),
      sessionTypes: _readOptions(json['sessionTypes'], 'sessionTypes'),
      locations: _readOptions(json['locations'], 'locations'),
      specialRequest: _optionalString(json['specialRequest']) ?? '',
      status: _optionalString(json['status']) ?? 'Pending',
      createdAt: _optionalDate(json['createdAt']),
    );
  }
}

List<TutorOption> _readOptions(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) {
    throw FormatException('Registration $field must be a list.');
  }
  return [
    for (final option in value)
      TutorOption.fromJson(_requiredMap(option, field)),
  ];
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Registration $field item must be an object.');
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = _optionalString(json[field]);
  if (value != null && value.isNotEmpty) return value;
  throw FormatException(
    'Registration field "$field" must be a non-empty string.',
  );
}

String _requiredId(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is num) return value.toString();
  throw const FormatException('Registration id must be a string or number.');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  throw const FormatException('Registration fields must be strings.');
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  throw const FormatException('Registration date must be a string or null.');
}
