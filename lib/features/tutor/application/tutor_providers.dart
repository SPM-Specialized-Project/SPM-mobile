import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/tutor_repository.dart';
import '../domain/tutor_course.dart';
import '../domain/tutor_course_workspace.dart';
import '../domain/tutor_registration.dart';
import '../domain/tutor_session.dart';
import '../domain/tutor_submission.dart';

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  return TutorRepository(ref.watch(apiClientProvider));
});

final tutorCoursesProvider = FutureProvider.autoDispose<List<TutorCourse>>((
  ref,
) {
  return ref.watch(tutorRepositoryProvider).getCourses();
});

final tutorSessionsProvider = FutureProvider.autoDispose<List<TutorSession>>((
  ref,
) {
  return ref.watch(tutorRepositoryProvider).getSessions();
});

final tutorSubmissionsProvider =
    FutureProvider.autoDispose<List<TutorSubmission>>((ref) {
      return ref.watch(tutorRepositoryProvider).getSubmissions();
    });

final tutorRegistrationsProvider =
    FutureProvider.autoDispose<List<TutorRegistration>>((ref) {
      return ref.watch(tutorRepositoryProvider).getRegistrations();
    });

final tutorCourseDetailProvider = FutureProvider.autoDispose
    .family<TutorCourseDetail, String>((ref, courseId) {
      return ref.watch(tutorRepositoryProvider).getCourseDetail(courseId);
    });

final tutorCourseRosterProvider = FutureProvider.autoDispose
    .family<CourseRoster, String>(
      (ref, id) => ref.watch(tutorRepositoryProvider).getRoster(id),
    );
final tutorCourseFeedbackProvider = FutureProvider.autoDispose
    .family<TutorCourseFeedback, String>(
      (ref, id) => ref.watch(tutorRepositoryProvider).getCourseFeedback(id),
    );
final tutorCourseSubmissionsProvider = FutureProvider.autoDispose
    .family<List<TutorSubmission>, String>((ref, id) async {
      final detail = await ref.watch(tutorCourseDetailProvider(id).future);
      return ref
          .watch(tutorRepositoryProvider)
          .getCourseSubmissions(detail.course);
    });
