import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/student_registration.dart';
import '../data/student_repository.dart';
import '../../learning/domain/class_session.dart';
import '../../learning/domain/course.dart';
import '../../learning/domain/course_submission.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(apiClientProvider));
});

final studentCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(studentRepositoryProvider).getCourses();
});

final studentSessionsProvider = FutureProvider.autoDispose<List<ClassSession>>((
  ref,
) {
  return ref.watch(studentRepositoryProvider).getSessions();
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
