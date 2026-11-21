import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../auth/data/auth_session.dart';
import '../../../learning/domain/class_session.dart';
import '../../../learning/presentation/widgets/session_month_navigator.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import 'student_courses_screen.dart';

class StudentSessionsScreen extends ConsumerStatefulWidget {
  const StudentSessionsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<StudentSessionsScreen> createState() =>
      _StudentSessionsScreenState();
}

class _StudentSessionsScreenState extends ConsumerState<StudentSessionsScreen> {
  DateTime _visibleMonth = _monthStart(DateTime.now());

  static DateTime _monthStart(DateTime value) =>
      DateTime(value.year, value.month);

  void _moveMonth(int offset) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentSessionsProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentSessionsProvider),
      ),
      data: (sessions) {
        final sorted = [...sessions]
          ..sort((a, b) => a.start.compareTo(b.start));
        final monthSessions = sorted
            .where((item) => isInSessionMonth(item.start, _visibleMonth))
            .toList(growable: false);
        final monthKey = '${_visibleMonth.year}-${_visibleMonth.month}';

        return RefreshIndicator(
          onRefresh: () => ref.refresh(studentSessionsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(
                'Lịch học',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Xem các buổi theo tháng, mở chi tiết rồi chuyển đến khóa học.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SessionMonthNavigator(
                month: _visibleMonth,
                sessionCount: monthSessions.length,
                onPrevious: () => _moveMonth(-1),
                onNext: () => _moveMonth(1),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: AppMotion.duration(context),
                transitionBuilder: (child, animation) =>
                    AppMotion.pageTransition(context, child, animation),
                child: monthSessions.isEmpty
                    ? SizedBox(
                        key: ValueKey('$monthKey:empty'),
                        height: 260,
                        child: TutorEmptyView(
                          icon: Icons.event_available_outlined,
                          title: sorted.isEmpty
                              ? 'Chưa có lịch học'
                              : 'Tháng này chưa có buổi học',
                          message: sorted.isEmpty
                              ? 'Lịch sẽ xuất hiện khi giảng viên tạo buổi cho khóa học bạn tham gia.'
                              : 'Dùng mũi tên hai bên tháng để xem lịch khác.',
                        ),
                      )
                    : Column(
                        key: ValueKey('$monthKey:items'),
                        children: [
                          for (final session in monthSessions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StudentSessionCard(
                                session: session,
                                onOpen: () => _showSessionDetails(
                                  context,
                                  session,
                                  widget.session,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentSessionCard extends StatelessWidget {
  const _StudentSessionCard({required this.session, required this.onOpen});

  final ClassSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final start = session.start.toLocal();
    final end = session.end.toLocal();
    final date =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
    final time =
        '${TimeOfDay.fromDateTime(start).format(context)} – ${TimeOfDay.fromDateTime(end).format(context)}';
    final online = session.method.toLowerCase() == 'online';
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TutorStatusPill(status: session.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              session.courseTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _SessionInfo(icon: Icons.calendar_today_outlined, text: date),
                _SessionInfo(icon: Icons.schedule_rounded, text: time),
                _SessionInfo(
                  icon: online ? Icons.videocam_outlined : Icons.place_outlined,
                  text: online
                      ? 'Trực tuyến'
                      : (session.location ?? 'Trực tiếp'),
                ),
              ],
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Chi tiết buổi học'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 5),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

void _showSessionDetails(
  BuildContext context,
  ClassSession session,
  AuthSession authSession,
) {
  final start = session.start.toLocal();
  final end = session.end.toLocal();
  final time =
      '${TimeOfDay.fromDateTime(start).format(context)} – ${TimeOfDay.fromDateTime(end).format(context)}';
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chi tiết buổi học',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(session.courseTitle),
            const SizedBox(height: 8),
            TutorStatusPill(status: session.status),
            const SizedBox(height: 16),
            _SessionInfo(
              icon: Icons.calendar_today_outlined,
              text: '${start.day}/${start.month}/${start.year}',
            ),
            const SizedBox(height: 8),
            _SessionInfo(icon: Icons.schedule_rounded, text: time),
            const SizedBox(height: 8),
            _SessionInfo(
              icon: session.method.toLowerCase() == 'online'
                  ? Icons.videocam_outlined
                  : Icons.place_outlined,
              text: session.method.toLowerCase() == 'online'
                  ? 'Trực tuyến'
                  : (session.location ?? 'Trực tiếp'),
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(session.description),
            ],
            if (session.link?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text('Liên kết buổi học'),
              const SizedBox(height: 4),
              SelectableText(session.link!),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentCourseDetailScreen(
                      courseId: session.courseId,
                      session: authSession,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Mở khóa học'),
            ),
          ],
        ),
      ),
    ),
  );
}
