import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/management_models.dart';
import '../data/management_repository.dart';
import '../../learning/domain/class_session.dart';
import '../../learning/domain/course.dart';
import '../../learning/domain/session_request.dart';

final managementRepositoryProvider = Provider<ManagementRepository>((ref) {
  return ManagementRepository(ref.watch(apiClientProvider));
});

final managerCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(managementRepositoryProvider).getCourses();
});

final managerCourseDetailProvider = FutureProvider.autoDispose
    .family<CourseDetail, String>((ref, courseId) {
      return ref.watch(managementRepositoryProvider).getCourseDetail(courseId);
    });

final managerSessionsProvider = FutureProvider.autoDispose<List<ClassSession>>((
  ref,
) {
  return ref.watch(managementRepositoryProvider).getSessions();
});

final managerSessionRequestsProvider =
    FutureProvider.autoDispose<List<SessionRequest>>((ref) {
      return ref.watch(managementRepositoryProvider).getSessionRequests();
    });

final managerRegistrationsProvider =
    FutureProvider.autoDispose<List<ManagedRegistration>>((ref) {
      return ref.watch(managementRepositoryProvider).getRegistrations();
    });

final courseRequestsProvider = FutureProvider.autoDispose<List<CourseRequest>>((
  ref,
) {
  return ref.watch(managementRepositoryProvider).getCourseRequests();
});
