import 'package:dio/dio.dart';

import '../../auth/data/auth_session.dart';
import '../domain/tutor_course.dart';
import '../domain/tutor_course_workspace.dart';
import '../domain/tutor_registration.dart';
import '../domain/tutor_session.dart';
import '../domain/tutor_submission.dart';

class TutorRepository {
  const TutorRepository(this._dio);

  final Dio _dio;

  Future<List<TutorCourse>> getCourses() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/courses');
    return _readItems(
      response.data,
      'courses',
    ).map(TutorCourse.fromJson).toList(growable: false);
  }

  Future<TutorCourseDetail> getCourseDetail(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/courses/${Uri.encodeComponent(courseId)}/detail',
    );
    final body = _requiredBody(response.data, 'course detail');
    return TutorCourseDetail.fromJson(body);
  }

  Future<List<TutorSession>> getSessions() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/sessions');
    return _readItems(
      response.data,
      'sessions',
    ).map(TutorSession.fromJson).toList(growable: false);
  }

  Future<TutorCourseDetail> saveCourseContent(
    String courseId,
    List<TutorCourseSection> sections,
    int expectedRevision,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/courses/${Uri.encodeComponent(courseId)}/detail',
      data: {
        'content': sections.map((item) => item.toJson()).toList(),
        'expectedRevision': expectedRevision,
      },
    );
    return TutorCourseDetail.fromJson(
      _requiredBody(response.data, 'course detail'),
    );
  }

  Future<CourseRoster> getRoster(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/classrooms/${Uri.encodeComponent(courseId)}/memberships',
    );
    return CourseRoster.fromJson(_requiredBody(response.data, 'roster'));
  }

  Future<void> addCourseMember(String courseId, String studentEmail) async {
    await _dio.post<Object?>(
      '/api/classrooms/${Uri.encodeComponent(courseId)}/memberships',
      data: {'studentEmail': studentEmail},
    );
  }

  Future<void> revokeCourseMember(String courseId, String membershipId) async {
    await _dio.patch<Object?>(
      '/api/classrooms/${Uri.encodeComponent(courseId)}/memberships/${Uri.encodeComponent(membershipId)}',
      data: {'status': 'REVOKED'},
    );
  }

  Future<TutorCourseFeedback> getCourseFeedback(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/courses/${Uri.encodeComponent(courseId)}/tutor-feedback',
    );
    return TutorCourseFeedback.fromJson(
      _requiredMap(
        _requiredBody(response.data, 'feedback')['item'],
        'feedback',
      ),
    );
  }

  Future<void> saveCourseFeedback(
    String courseId,
    TutorCourseFeedback feedback,
  ) async {
    await _dio.patch<Object?>(
      '/api/courses/${Uri.encodeComponent(courseId)}/tutor-feedback',
      data: {
        'courseComment': feedback.courseComment,
        'studentComments': feedback.studentComments,
        'expectedRevision': feedback.revision,
      },
    );
  }

  Future<List<TutorSubmission>> getCourseSubmissions(TutorCourse course) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/courses/${Uri.encodeComponent(course.id)}/submissions',
      );
      return _readItems(response.data, 'submissions')
          .map(
            (json) => TutorSubmission.fromJson({
              ...json,
              'courseTitle': course.title,
            }),
          )
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 &&
          (error.response?.data as Map?)?['code'] == 'ASSIGNMENT_NOT_FOUND') {
        return [];
      }
      rethrow;
    }
  }

  Future<TutorSession> createSession({
    required TutorCourse course,
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
    final body = _requiredBody(response.data, 'create session');
    return TutorSession.fromJson(_requiredMap(body['item'], 'session item'));
  }

  Future<List<TutorSubmission>> getSubmissions() async {
    final courses = await getCourses();
    final submissionsByCourse = await Future.wait(
      courses.map((course) async {
        try {
          final response = await _dio.get<Map<String, dynamic>>(
            '/api/courses/${Uri.encodeComponent(course.id)}/submissions',
          );
          return _readItems(response.data, 'submissions')
              .map(
                (json) => TutorSubmission.fromJson({
                  ...json,
                  'courseTitle': course.title,
                }),
              )
              .toList(growable: false);
        } on DioException catch (error) {
          // A course without assignments has no submission list yet.
          if (error.response?.statusCode == 404) {
            return const <TutorSubmission>[];
          }
          rethrow;
        }
      }),
    );

    return submissionsByCourse.expand((items) => items).toList(growable: false);
  }

  Future<TutorSubmission> gradeSubmission({
    required String submissionId,
    required double score,
    required String feedback,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/submissions/${Uri.encodeComponent(submissionId)}',
      data: {'score': score, 'feedback': feedback.trim()},
    );
    final body = _requiredBody(response.data, 'update submission');
    return TutorSubmission.fromJson(
      _requiredMap(body['item'], 'submission item'),
    );
  }

  Future<List<TutorRegistration>> getRegistrations() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/registrations',
      queryParameters: const {'registrationType': 'tutor'},
    );
    return _readItems(
      response.data,
      'registrations',
    ).map(TutorRegistration.fromJson).toList(growable: false);
  }

  Future<TutorRegistration> createRegistration({
    required AuthSession session,
    required List<TutorCourse> courses,
    required List<TutorOption> languages,
    required List<TutorOption> sessionTypes,
    required List<TutorOption> locations,
    required String specialRequest,
    String? meetLink,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/registrations',
      data: {
        'registrationType': 'tutor',
        'item': {
          'Name': session.user.name,
          'Email': session.user.email,
          'subjects': courses
              .map(
                (course) => {
                  'id': course.id,
                  'name': '${course.title} (${course.code})',
                },
              )
              .toList(growable: false),
          'languages': languages.map((item) => item.toJson()).toList(),
          'sessionTypes': sessionTypes.map((item) => item.toJson()).toList(),
          'locations': locations.map((item) => item.toJson()).toList(),
          if (meetLink != null && meetLink.trim().isNotEmpty)
            'meetLink': meetLink.trim(),
          'specialRequest': specialRequest.trim(),
          'status': 'Pending',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );
    final body = _requiredBody(response.data, 'create tutor registration');
    return TutorRegistration.fromJson(
      _requiredMap(body['item'], 'registration item'),
    );
  }
}

List<Map<String, dynamic>> _readItems(
  Map<String, dynamic>? body,
  String resourceName,
) {
  final items = _requiredBody(body, resourceName)['items'];
  if (items is! List) {
    throw FormatException('Backend $resourceName response must contain items.');
  }
  return [for (final item in items) _requiredMap(item, '$resourceName item')];
}

Map<String, dynamic> _requiredBody(
  Map<String, dynamic>? body,
  String resourceName,
) {
  if (body != null) return body;
  throw FormatException('Backend returned an empty $resourceName response.');
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Backend $field must be an object.');
}
