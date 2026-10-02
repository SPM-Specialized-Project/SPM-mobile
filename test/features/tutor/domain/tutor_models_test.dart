import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_registration.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_session.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_submission.dart';

void main() {
  group('TutorCourse', () {
    test('parses course summary and roster returned by the backend', () {
      final course = TutorCourse.fromJson({
        'id': 12,
        'code': 'CS101',
        'title': 'Cấu trúc dữ liệu',
        'instructor': 'Tutor User',
        'stats': {'documents': 3, 'links': 2, 'assignments': 1},
        'students': [
          {'id': 'student-1', 'name': 'Nguyễn An', 'email': 'an@example.com'},
        ],
      });

      expect(course.id, '12');
      expect(course.title, 'Cấu trúc dữ liệu');
      expect(course.assignmentCount, 1);
      expect(course.students.single.name, 'Nguyễn An');
    });

    test('rejects malformed required fields instead of inventing a course', () {
      expect(
        () => TutorCourse.fromJson({'id': '1', 'title': ''}),
        throwsFormatException,
      );
    });

    test('parses content sections from the course detail endpoint', () {
      final detail = TutorCourseDetail.fromJson({
        'course': {
          'id': '1',
          'code': 'CS101',
          'title': 'Lập trình',
          'students': [],
        },
        'detail': {
          'content': [
            {'id': 'intro', 'type': 'introduction', 'title': 'Giới thiệu'},
          ],
        },
      });

      expect(detail.course.id, '1');
      expect(detail.sections.single.type, 'introduction');
    });
  });

  test('parses session timestamps and online details', () {
    final session = TutorSession.fromJson({
      'id': 'session-1',
      'courseId': '1',
      'courseTitle': 'Lập trình',
      'title': 'Ôn tập',
      'desc': 'Chương 1',
      'start': '2026-10-10T02:00:00.000Z',
      'end': '2026-10-10T03:00:00.000Z',
      'method': 'online',
      'status': 'scheduled',
      'link': 'https://meet.example.com',
    });

    expect(session.start.isUtc, isTrue);
    expect(session.method, 'online');
    expect(session.link, 'https://meet.example.com');
  });

  test('parses submission with nullable score and nested student/assignment', () {
    final submission = TutorSubmission.fromJson({
      'id': 'submission-1',
      'courseId': '1',
      'courseTitle': 'Lập trình',
      'student': {
        'id': 'student-1',
        'name': 'Nguyễn An',
        'email': 'an@example.com',
      },
      'assignment': {'id': 'assignment-1', 'title': 'Bài 1'},
      'status': 'submitted',
      'score': null,
      'feedback': '',
      'submittedAt': '2026-10-01T12:30:00Z',
      'fileUrl': '/uploads/answer.pdf',
    });

    expect(submission.studentName, 'Nguyễn An');
    expect(submission.assignmentTitle, 'Bài 1');
    expect(submission.score, isNull);
    expect(submission.submittedAt, isNotNull);
  });

  test('parses tutor registration statuses case-insensitively', () {
    final registration = TutorRegistration.fromJson({
      'id': 'registration-1',
      'Name': 'Tutor User',
      'Email': 'tutor@example.com',
      'subjects': [
        {'id': '1', 'name': 'Lập trình'},
      ],
      'languages': [
        {'id': 'vi', 'name': 'Tiếng Việt'},
      ],
      'sessionTypes': [
        {'id': 'online', 'name': 'Trực tuyến'},
      ],
      'locations': [],
      'specialRequest': 'Có thể dạy buổi tối.',
      'status': 'Pending',
      'createdAt': '2026-10-01T10:00:00Z',
    });

    expect(registration.subjects.single.id, '1');
    expect(registration.status, 'Pending');
  });
}
