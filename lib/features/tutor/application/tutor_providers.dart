import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/tutor_repository.dart';
import '../domain/tutor_course.dart';
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
