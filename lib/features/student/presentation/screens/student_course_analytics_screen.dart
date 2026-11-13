import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/course_submission.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import 'student_submissions_screen.dart';

class StudentCourseAnalyticsScreen extends ConsumerWidget {
  const StudentCourseAnalyticsScreen({
    required this.courseId,
    required this.courseTitle,
    super.key,
  });

  final String courseId;
  final String courseTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentSubmissionsProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentSubmissionsProvider),
      ),
      data: (allSubmissions) {
        final submissions = allSubmissions
            .where((item) => item.courseId == courseId)
            .toList(growable: false);
        final submitted = submissions
            .where((item) => item.submittedAt != null)
            .length;
        final graded = submissions.where((item) => item.score != null).toList();
        final average = graded.isEmpty
            ? null
            : graded.fold<double>(0, (sum, item) => sum + item.score!) /
                  graded.length;

        return RefreshIndicator(
          onRefresh: () => ref.refresh(studentSubmissionsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Text(
                'Tiến độ học tập',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(courseTitle),
              const SizedBox(height: 14),
              const _AnalyticsScopeNotice(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: columns == 2 ? 1.55 : 1.35,
                    children: [
                      _AnalyticsMetric(
                        label: 'Bài tập từ API',
                        value: '${submissions.length}',
                        icon: Icons.assignment_outlined,
                      ),
                      _AnalyticsMetric(
                        label: 'Đã nộp',
                        value: '$submitted',
                        icon: Icons.upload_file_outlined,
                      ),
                      _AnalyticsMetric(
                        label: 'Đã chấm',
                        value: '${graded.length}',
                        icon: Icons.fact_check_outlined,
                      ),
                      _AnalyticsMetric(
                        label: 'Điểm trung bình',
                        value: average?.toStringAsFixed(1) ?? '—',
                        icon: Icons.grade_outlined,
                      ),
                    ],
                  );
                },
              ),
              if (submissions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Tỷ lệ đã nộp')),
                            Text('$submitted / ${submissions.length}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: submitted / submissions.length,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Theo bài tập',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (submissions.isEmpty)
                const TutorEmptyView(
                  icon: Icons.query_stats_rounded,
                  title: 'Chưa có dữ liệu bài tập',
                  message:
                      'Tiến độ sẽ xuất hiện khi API trả về bài tập của khóa học.',
                )
              else
                for (final item in submissions) ...[
                  _SubmissionProgressTile(
                    submission: item,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => StudentSubmissionDetailScreen(
                          submissionId: item.id,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsScopeNotice extends StatelessWidget {
  const _AnalyticsScopeNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Text(
          'Chỉ số dựa trên bài nộp của tài khoản đang đăng nhập mà API trả về; đây không phải thống kê của cả lớp.',
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colors.primary),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionProgressTile extends StatelessWidget {
  const _SubmissionProgressTile({
    required this.submission,
    required this.onTap,
  });

  final CourseSubmission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSubmitted = submission.submittedAt != null;
    final status = !isSubmitted
        ? 'Chưa nộp'
        : submission.score == null
        ? 'Chờ chấm'
        : 'Đã chấm';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: ListTile(
        leading: Icon(
          submission.score != null
              ? Icons.task_alt_rounded
              : isSubmitted
              ? Icons.hourglass_top_rounded
              : Icons.assignment_outlined,
          color: submission.score != null
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
        title: Text(
          submission.assignmentTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(status),
        trailing: submission.score == null
            ? const Icon(Icons.chevron_right_rounded)
            : Text(
                submission.score!.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium,
              ),
        onTap: onTap,
      ),
    );
  }
}
