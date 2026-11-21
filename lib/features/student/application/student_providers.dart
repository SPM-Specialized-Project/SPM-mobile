import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/student_registration.dart';
import '../data/student_codepulse_repository.dart';
import '../data/student_repository.dart';
import '../../learning/domain/class_session.dart';
import '../../learning/domain/course.dart';
import '../../learning/domain/course_submission.dart';
import '../../learning/domain/session_request.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(apiClientProvider));
});

final studentCodePulseRepositoryProvider = Provider<StudentCodePulseRepository>(
  (ref) => StudentCodePulseRepository(ref.watch(apiClientProvider)),
);

final studentCodePulseClassroomsProvider = FutureProvider.autoDispose
    .family<List<StudentCodePulseClassroom>, String>((ref, courseId) {
      return ref
          .watch(studentCodePulseRepositoryProvider)
          .getClassrooms(courseId);
    });

final studentCodePulseClassroomWorkProvider = FutureProvider.autoDispose
    .family<StudentCodePulseClassroomWork, String>((ref, classroomId) {
      return ref
          .watch(studentCodePulseRepositoryProvider)
          .getClassroomWork(classroomId);
    });

final studentCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(studentRepositoryProvider).getCourses();
});

final studentSessionsProvider = FutureProvider.autoDispose<List<ClassSession>>((
  ref,
) {
  return ref.watch(studentRepositoryProvider).getSessions();
});

final studentSessionRequestsProvider =
    FutureProvider.autoDispose<List<SessionRequest>>((ref) {
      return ref.watch(studentRepositoryProvider).getSessionRequests();
    });

final studentSubmissionsProvider =
    FutureProvider.autoDispose<List<CourseSubmission>>((ref) {
      return ref.watch(studentRepositoryProvider).getSubmissions();
    });

final studentRegistrationsProvider =
    FutureProvider.autoDispose<List<StudentRegistration>>((ref) {
      return ref.watch(studentRepositoryProvider).getRegistrations();
    });

final studentCourseDetailProvider = FutureProvider.autoDispose
    .family<CourseDetail, String>((ref, courseId) {
      return ref.watch(studentRepositoryProvider).getCourseDetail(courseId);
    });
