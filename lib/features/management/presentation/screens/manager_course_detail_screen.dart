import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/course.dart';
import '../../../learning/presentation/member_profile_screen.dart';
import '../../application/management_providers.dart';
import '../widgets/management_common.dart';

class ManagerCourseDetailScreen extends ConsumerWidget {
  const ManagerCourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerCourseDetailProvider(courseId));
    return state.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: const ManagementLoading(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: ManagementError(
          message: managementErrorMessage(error),
          onRetry: () => ref.invalidate(managerCourseDetailProvider(courseId)),
        ),
      ),
      data: (detail) {
        final course = detail.course;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(managerCourseDetailProvider(courseId).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                Text(
                  course.code,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text('Giảng viên: ${course.instructor}'),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: columns == 2 ? 1.45 : 1.4,
                      children: [
                        _CourseMetric(
                          label: 'Thành viên',
                          value: course.students.length,
                          icon: Icons.people_outline_rounded,
                        ),
                        _CourseMetric(
                          label: 'Tài liệu',
                          value: course.documentCount,
                          icon: Icons.description_outlined,
                        ),
                        _CourseMetric(
                          label: 'Liên kết',
                          value: course.linkCount,
                          icon: Icons.link_rounded,
                        ),
                        _CourseMetric(
                          label: 'Bài tập',
                          value: course.assignmentCount,
                          icon: Icons.assignment_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (detail.sections.isNotEmpty) ...[
                  Text(
                    'Nội dung khóa học',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _CourseDetailScopeNotice(),
                  const SizedBox(height: 8),
                  for (final section in detail.sections) ...[
                    _CourseContentCard(section: section),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  'Danh sách học viên',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (course.students.isEmpty)
                  const ManagementEmpty(
                    title: 'Chưa có học viên',
                    message: 'API chưa trả thành viên trong khóa học này.',
                  )
                else
                  for (final student in course.students)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            student.name.isEmpty
                                ? '?'
                                : student.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: Text(student.email),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => MemberProfileScreen(
                              memberId: student.id,
                              name: student.name,
                              email: student.email,
                              courseId: course.id,
                              courseTitle: course.title,
                              courseCode: course.code,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourseMetric extends StatelessWidget {
  const _CourseMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
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
              '$value',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CourseDetailScopeNotice extends StatelessWidget {
  const _CourseDetailScopeNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Text(
          'Nội dung học liệu do backend hiện cung cấp ở dạng mẫu. Thông tin bên dưới phản ánh payload trả về.',
          style: TextStyle(color: colors.onTertiaryContainer),
        ),
      ),
    );
  }
}

class _CourseContentCard extends StatelessWidget {
  const _CourseContentCard({required this.section});

  final CourseSection section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = section.data;
    final key = switch (section.type) {
      'material' => 'document',
      'movie' => 'video',
      'note' => 'assignment',
      'bookReference' => 'books',
      'introduction' => 'text',
      'submission' => null,
      _ => 'link',
    };
    final nested = key == null ? null : data[key];
    final details = <String>[
      if (section.description.isNotEmpty) section.description,
      if (nested is Map)
        for (final value in nested.entries)
          if (value.value != null && value.value.toString().isNotEmpty)
            '${value.key}: ${value.value}',
      if (section.type == 'submission' && data['dueDate'] != null)
        'Hạn nộp: ${data['dueDate']}',
    ];
    if (nested is String && nested.isNotEmpty) details.add(nested);
    if (nested is List) {
      for (final item in nested) {
        if (item is Map) {
          for (final value in item.entries) {
            if (value.value != null && value.value.toString().isNotEmpty) {
              details.add('${value.key}: ${value.value}');
            }
          }
        } else if (item != null && item.toString().isNotEmpty) {
          details.add(item.toString());
        }
      }
    }
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: ExpansionTile(
        leading: Icon(_iconForSection(section.type), color: colors.primary),
        title: Text(section.title),
        subtitle: Text(section.type),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (details.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Chưa có nội dung chi tiết.'),
            )
          else
            for (final line in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: SelectableText(line),
              ),
        ],
      ),
    );
  }
}

IconData _iconForSection(String type) => switch (type) {
  'introduction' => Icons.info_outline_rounded,
  'material' => Icons.description_outlined,
  'movie' => Icons.play_circle_outline_rounded,
  'note' || 'submission' => Icons.assignment_outlined,
  'reference' || 'bookReference' => Icons.link_rounded,
  _ => Icons.article_outlined,
};
