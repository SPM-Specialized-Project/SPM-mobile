import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../../learning/domain/class_session.dart';
import '../../learning/domain/course.dart';
import '../../learning/domain/session_request.dart';
import '../../management/data/management_models.dart';

class ManagementRepository {
  const ManagementRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> getCourses() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/courses');
    return _readItems(
      response.data,
      'courses',
    ).map(Course.fromJson).toList(growable: false);
  }

  Future<CourseDetail> getCourseDetail(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/courses/${Uri.encodeComponent(courseId)}/detail',
    );
    final body = _body(response.data, 'course detail');
    return CourseDetail.fromJson(body);
  }

  Future<List<ClassSession>> getSessions() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/sessions');
    return _readItems(
      response.data,
      'sessions',
    ).map(ClassSession.fromJson).toList(growable: false);
  }

  Future<List<SessionRequest>> getSessionRequests() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/session-requests',
    );
    return _readItems(
      response.data,
      'session requests',
    ).map(SessionRequest.fromJson).toList(growable: false);
  }

  Future<SessionRequest> reviewSessionRequest({
    required String id,
    required String status,
    required String reason,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/session-requests/${Uri.encodeComponent(id)}',
      data: {
        'status': status,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return SessionRequest.fromJson(
      _requiredMap(
        _body(response.data, 'session request')['item'],
        'session request item',
      ),
    );
  }

  Future<SessionRequest> scheduleSessionRequest({
    required String id,
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String method,
    String? link,
    String? location,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/session-requests/${Uri.encodeComponent(id)}/schedule',
      data: {
        'title': title.trim(),
        'description': description.trim(),
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'method': method,
        if (method == 'online' && link != null) 'link': link.trim(),
        if (method == 'offline' && location != null)
          'location': location.trim(),
      },
    );
    return SessionRequest.fromJson(
      _requiredMap(
        _body(response.data, 'scheduled session request')['item'],
        'scheduled session request item',
      ),
    );
  }

  Future<ClassSession> createSession({
    required Course course,
    required AuthSession session,
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String method,
    String? link,
    String? location,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sessions',
      data: {
        'item': {
          'courseId': course.id,
          'courseTitle': course.title,
          'title': title.trim(),
          'desc': description.trim(),
          'instructor': session.user.name,
          'method': method,
          if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
          if (location != null && location.trim().isNotEmpty)
            'location': location.trim(),
          'start': start.toUtc().toIso8601String(),
          'end': end.toUtc().toIso8601String(),
          'status': 'scheduled',
          'requestType': 'new',
        },
      },
    );
    final item = _body(response.data, 'session')['item'];
    return ClassSession.fromJson(_requiredMap(item, 'session item'));
  }

  Future<ClassSession> updateSession({
    required String id,
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required String method,
    String? link,
    String? location,
    String? status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/sessions/${Uri.encodeComponent(id)}',
      data: {
        'patch': {
          'title': title.trim(),
          'desc': description.trim(),
          'start': start.toUtc().toIso8601String(),
          'end': end.toUtc().toIso8601String(),
          'method': method,
          'link': method == 'online' && (link?.trim().isNotEmpty ?? false)
              ? link!.trim()
              : null,
          'location':
              method == 'offline' && (location?.trim().isNotEmpty ?? false)
              ? location!.trim()
              : null,
          'status': ?status,
        },
      },
    );
    final item = _body(response.data, 'updated session')['item'];
    return ClassSession.fromJson(_requiredMap(item, 'session item'));
  }

  Future<void> updateSessionStatus(String id, String status) async {
    await _dio.patch<Object?>(
      '/api/sessions/${Uri.encodeComponent(id)}',
      data: {
        'patch': {'status': status},
      },
    );
  }

  Future<List<ManagedRegistration>> getRegistrations() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/registrations');
    return _readItems(
      response.data,
      'registrations',
    ).map(ManagedRegistration.fromJson).toList(growable: false);
  }

  Future<ManagedRegistration> updateRegistration({
    required String id,
    required String status,
    String reason = '',
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/registrations/${Uri.encodeComponent(id)}',
      data: {
        'patch': {
          'status': status,
          if (reason.trim().isNotEmpty) 'declineReason': reason.trim(),
        },
      },
    );
    return ManagedRegistration.fromJson(
      _requiredMap(
        _body(response.data, 'registration')['item'],
        'registration item',
      ),
    );
  }

  Future<List<CourseRequest>> getCourseRequests() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/course-requests',
    );
    return _readItems(
      response.data,
      'course requests',
    ).map(CourseRequest.fromJson).toList(growable: false);
  }

  Future<CourseRequest> createCourseRequest({
    required AuthSession session,
    required String courseName,
    required String courseCode,
    required String description,
    required List<ManagementOption> languages,
    required List<ManagementOption> sessionTypes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/course-requests',
      data: {
        'item': {
          'coordinatorName': session.user.name,
          'coordinatorEmail': session.user.email,
          'courseName': courseName.trim(),
          'courseCode': courseCode.trim().toUpperCase(),
          'description': description.trim(),
          'languages': languages.map(_optionJson).toList(growable: false),
          'sessionTypes': sessionTypes.map(_optionJson).toList(growable: false),
          'locations': const <Map<String, String>>[],
          'status': 'Pending',
          'reasons': '',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );
    return CourseRequest.fromJson(
      _requiredMap(
        _body(response.data, 'course request')['item'],
        'course request item',
      ),
    );
  }

  Future<CourseRequest> reviewCourseRequest({
    required String id,
    required String status,
    required String reason,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/course-requests/${Uri.encodeComponent(id)}',
      data: {
        'patch': {'status': status, 'reasons': reason.trim()},
      },
    );
    return CourseRequest.fromJson(
      _requiredMap(
        _body(response.data, 'course request')['item'],
        'course request item',
      ),
    );
  }
}

List<Map<String, dynamic>> _readItems(Map<String, dynamic>? data, String name) {
  final items = _body(data, name)['items'];
  if (items is! List) {
    throw FormatException('Backend $name response must contain items.');
  }
  return [for (final item in items) _requiredMap(item, '$name item')];
}

Map<String, dynamic> _body(Map<String, dynamic>? data, String name) {
  if (data != null) return data;
  throw FormatException('Backend returned an empty $name response.');
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$field must be an object.');
}

Map<String, String> _optionJson(ManagementOption option) => {
  'id': option.id,
  'name': option.name,
};
