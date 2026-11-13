import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../../learning/domain/class_session.dart';
import '../../learning/domain/course.dart';
import '../../learning/domain/course_submission.dart';
import '../../learning/domain/session_request.dart';
import 'student_registration.dart';

class StudentRepository {
  const StudentRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> getCourses() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/courses');
    return _items(
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
    return _items(
      response.data,
      'sessions',
    ).map(ClassSession.fromJson).toList(growable: false);
  }

  Future<List<SessionRequest>> getSessionRequests() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/session-requests',
    );
    return _items(
      response.data,
      'session requests',
    ).map(SessionRequest.fromJson).toList(growable: false);
  }

  Future<SessionRequest> createSessionRequest({
    required String courseId,
    required String requestType,
    required String title,
    required String description,
    required DateTime proposedAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/session-requests',
      data: {
        'courseId': courseId,
        'requestType': requestType,
        'title': title.trim(),
        'description': description.trim(),
        'proposedAt': proposedAt.toUtc().toIso8601String(),
      },
    );
    final item = _body(response.data, 'session request')['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'Backend session request response must contain item.',
      );
    }
    return SessionRequest.fromJson(item);
  }

  Future<List<CourseSubmission>> getSubmissions() async {
    final courses = await getCourses();
    final perCourse = await Future.wait(
      courses.map((course) async {
        final detail = await getCourseDetail(course.id);
        final assignments = detail.sections
            .where((section) => section.type == 'submission')
            .toList(growable: false);
        final perAssignment = await Future.wait(
          assignments.map((assignment) async {
            final response = await _dio.get<Map<String, dynamic>>(
              '/api/courses/${Uri.encodeComponent(course.id)}/submissions',
              queryParameters: {'assignmentId': assignment.id},
            );
            return _items(response.data, 'submissions')
                .map(
                  (json) => CourseSubmission.fromJson({
                    ...json,
                    'courseTitle': course.title,
                  }),
                )
                .toList(growable: false);
          }),
        );
        return perAssignment.expand((items) => items).toList(growable: false);
      }),
    );
    return perCourse.expand((items) => items).toList(growable: false);
  }

  Future<CourseSubmission> submitLink({
    required String submissionId,
    required Uri fileUri,
  }) async {
    if (!{'http', 'https'}.contains(fileUri.scheme) || fileUri.host.isEmpty) {
      throw const FormatException(
        'Bài nộp cần là một liên kết HTTP hoặc HTTPS hợp lệ.',
      );
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/submissions/${Uri.encodeComponent(submissionId)}',
      data: {
        'fileUrl': fileUri.toString(),
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    final body = _body(response.data, 'submission');
    final item = body['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'Backend submission response must contain item.',
      );
    }
    return CourseSubmission.fromJson(item);
  }

  Future<List<StudentRegistration>> getRegistrations() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/registrations',
      queryParameters: const {'registrationType': 'student'},
    );
    return _items(
      response.data,
      'registrations',
    ).map(StudentRegistration.fromJson).toList(growable: false);
  }

  Future<StudentRegistration> createRegistration({
    required AuthSession session,
    required Course course,
    required StudentOption language,
    required StudentOption sessionType,
    StudentOption? location,
    required String specialRequest,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/registrations',
      data: {
        'registrationType': 'student',
        'item': {
          'Name': session.user.name,
          'Email': session.user.email,
          'subjects': [
            {'id': course.id, 'name': '${course.title} (${course.code})'},
          ],
          'languages': [_optionJson(language)],
          'sessionTypes': [_optionJson(sessionType)],
          if (location != null) 'locations': [_optionJson(location)],
          'specialRequest': specialRequest.trim(),
          'status': 'Pending',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );
    final body = _body(response.data, 'registration');
    final item = body['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'Backend registration response must contain item.',
      );
    }
    return StudentRegistration.fromJson(item);
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? data, String resource) {
  if (data != null) return data;
  throw FormatException('Backend returned an empty $resource response.');
}

List<Map<String, dynamic>> _items(Map<String, dynamic>? data, String resource) {
  final items = _body(data, resource)['items'];
  if (items is! List) {
    throw FormatException('Backend $resource must contain items.');
  }
  return [
    for (final item in items)
      if (item is Map<String, dynamic>)
        item
      else
        throw FormatException('Backend $resource item must be an object.'),
  ];
}

Map<String, String> _optionJson(StudentOption option) => {
  'id': option.id,
  'name': option.name,
};
