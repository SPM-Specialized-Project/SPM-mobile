import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/class_session.dart';
import '../../../learning/domain/course.dart';
import '../../application/management_providers.dart';
import '../../data/management_models.dart';
import '../widgets/management_common.dart';
import 'manager_reports_screen.dart';

/// Course overview for the web `/statistical/overview` route.
///
/// The web screen displays invented sample timestamps. Mobile derives the
/// latest date and session count from records returned for the current user.
class ManagerStatisticsOverviewScreen extends ConsumerWidget {
  const ManagerStatisticsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesState = ref.watch(managerCoursesProvider);
    final sessionsState = ref.watch(managerSessionsProvider);
    final registrationsState = ref.watch(managerRegistrationsProvider);

    if (coursesState.isLoading ||
        sessionsState.isLoading ||
        registrationsState.isLoading) {
      return const Scaffold(body: ManagementLoading());
    }

    final error =
        coursesState.error ?? sessionsState.error ?? registrationsState.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thống kê theo khóa học')),
        body: ManagementError(
          message: managementErrorMessage(error),
          onRetry: () {
            ref.invalidate(managerCoursesProvider);
            ref.invalidate(managerSessionsProvider);
            ref.invalidate(managerRegistrationsProvider);
          },
        ),
      );
    }

    final courses = coursesState.value ?? const <Course>[];
    final sessions = sessionsState.value ?? const <ClassSession>[];
    final registrations =
        registrationsState.value ?? const <ManagedRegistration>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê theo khóa học')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(managerCoursesProvider.future),
            ref.refresh(managerSessionsProvider.future),
            ref.refresh(managerRegistrationsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const ManagementPageHeader(
              title: 'Tổng quan môn học',
              subtitle:
                  'Thời điểm và số buổi lấy từ lịch mà API trả về cho tài khoản.',
            ),
            if (courses.isEmpty)
              const SizedBox(
                height: 260,
                child: ManagementEmpty(
                  title: 'Chưa có khóa học',
                  message: 'Backend chưa trả khóa học nào cho tài khoản này.',
                ),
              )
            else
              for (final course in courses) ...[
                _StatisticsCourseCard(
                  course: course,
                  sessions: sessions
                      .where((session) => session.courseId == course.id)
                      .toList(growable: false),
                  registrations: registrations
                      .where(
                        (registration) => registration.subjects.any(
                          (subject) => subject.id == course.id,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _StatisticsCourseCard extends StatelessWidget {
  const _StatisticsCourseCard({
    required this.course,
    required this.sessions,
    required this.registrations,
  });

  final Course course;
  final List<ClassSession> sessions;
  final List<ManagedRegistration> registrations;

  @override
  Widget build(BuildContext context) {
    final orderedSessions = sessions.toList()
      ..sort((left, right) => right.start.compareTo(left.start));
    final latestSession = orderedSessions.firstOrNull;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ManagerCourseReportScreen(
              course: course,
              sessionCount: sessions.length,
              registrations: registrations,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: const Icon(Icons.menu_book_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.code,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    icon: Icons.people_outline_rounded,
                    label: '${course.students.length} thành viên',
                  ),
                  _SummaryChip(
                    icon: Icons.event_note_outlined,
                    label: '${sessions.length} buổi',
                  ),
                  _SummaryChip(
                    icon: Icons.assignment_outlined,
                    label: '${course.assignmentCount} bài tập',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      latestSession == null
                          ? 'Chưa có buổi học trong dữ liệu API'
                          : 'Buổi gần nhất: ${MaterialLocalizations.of(context).formatMediumDate(latestSession.start.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(latestSession.start.toLocal()))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    visualDensity: VisualDensity.compact,
    side: BorderSide.none,
  );
}
