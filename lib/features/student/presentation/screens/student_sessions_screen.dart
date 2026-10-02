import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/class_session.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';

class StudentSessionsScreen extends ConsumerWidget {
  const StudentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Các buổi thuộc khóa học bạn đang tham gia. Màn hình này chỉ xem, không tạo hoặc sửa buổi học.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (sorted.isEmpty)
                const SizedBox(
                  height: 260,
                  child: TutorEmptyView(
                    icon: Icons.event_available_outlined,
                    title: 'Chưa có lịch học',
                    message:
                        'Lịch sẽ xuất hiện khi giảng viên tạo buổi cho khóa học của bạn.',
                  ),
                )
              else
                for (final session in sorted) ...[
                  _StudentSessionCard(session: session),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _StudentSessionCard extends StatelessWidget {
  const _StudentSessionCard({required this.session});

  final ClassSession session;

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
              Text(session.description),
            ],
            if (session.link != null && session.link!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Liên kết buổi học',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SelectableText(
                session.link!,
                style: TextStyle(
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
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
