class SessionRequest {
  const SessionRequest({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.requesterEmail,
    required this.requestType,
    required this.title,
    required this.description,
    required this.proposedAt,
    required this.status,
    required this.reviewReason,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.scheduledSessionId,
    this.scheduledStart,
    this.scheduledEnd,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String requesterEmail;
  final String requestType;
  final String title;
  final String description;
  final DateTime proposedAt;
  final String status;
  final String reviewReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? scheduledSessionId;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  factory SessionRequest.fromJson(Map<String, dynamic> json) {
    final proposedAt = DateTime.tryParse(
      _sessionRequestString(json, 'proposedAt'),
    );
    if (proposedAt == null) {
      throw const FormatException(
        'Session request proposedAt must be an ISO date.',
      );
    }
    return SessionRequest(
      id: _sessionRequestString(json, 'id'),
      courseId: _sessionRequestString(json, 'courseId'),
      courseTitle: _sessionRequestString(json, 'courseTitle'),
      requesterEmail: _sessionRequestString(json, 'requesterEmail'),
      requestType: _sessionRequestString(json, 'requestType'),
      title: _sessionRequestString(json, 'title'),
      description: _sessionRequestString(json, 'description', allowEmpty: true),
      proposedAt: proposedAt,
      status: _sessionRequestString(json, 'status'),
      reviewReason: _sessionRequestString(
        json,
        'reviewReason',
        allowEmpty: true,
      ),
      createdAt: _sessionRequestDate(json['createdAt']),
      updatedAt: _sessionRequestDate(json['updatedAt']),
      reviewedAt: _sessionRequestDate(json['reviewedAt']),
      reviewedBy: _sessionRequestOptionalString(json['reviewedBy']),
      scheduledSessionId: _sessionRequestOptionalString(
        json['scheduledSessionId'],
      ),
      scheduledStart: _sessionRequestDate(json['scheduledStart']),
      scheduledEnd: _sessionRequestDate(json['scheduledEnd']),
    );
  }
}

String _sessionRequestString(
  Map<String, dynamic> json,
  String key, {
  bool allowEmpty = false,
}) {
  final value = json[key];
  if (value is String && (allowEmpty || value.trim().isNotEmpty)) {
    return value.trim();
  }
  throw FormatException('Session request field "$key" must be text.');
}

DateTime? _sessionRequestDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String? _sessionRequestOptionalString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
