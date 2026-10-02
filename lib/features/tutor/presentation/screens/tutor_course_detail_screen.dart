import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../widgets/tutor_ui.dart';

class TutorCourseDetailScreen extends ConsumerWidget {
  const TutorCourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(tutorCourseDetailProvider(courseId));

    return detailState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: const TutorLoadingView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(tutorCourseDetailProvider(courseId)),
        ),
      ),
      data: (detail) => _CourseDetailContent(detail: detail),
    );
  }
}

class _CourseDetailContent extends StatelessWidget {
  const _CourseDetailContent({required this.detail});

  final TutorCourseDetail detail;

  @override
  Widget build(BuildContext context) {
    final course = detail.course;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nội dung'),
              Tab(text: 'Sinh viên'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CourseContentTab(course: course, sections: detail.sections),
            _CourseRosterTab(students: course.students),
          ],
        ),
      ),
    );
  }
}

class _CourseContentTab extends StatelessWidget {
  const _CourseContentTab({required this.course, required this.sections});

  final TutorCourse course;
  final List<TutorCourseSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(course.code, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(course.instructor, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Text(
          'Nội dung khóa học',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (sections.isEmpty)
          const TutorEmptyView(
            icon: Icons.menu_book_outlined,
            title: 'Chưa có nội dung',
            message: 'Backend chưa cung cấp nội dung cho khóa học này.',
          )
        else
          for (final section in sections)
            Card(
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(_contentIcon(section.type)),
                ),
                title: Text(section.title),
                subtitle: Text(_contentTypeLabel(section.type)),
              ),
            ),
      ],
    );
  }
}

class _CourseRosterTab extends StatelessWidget {
  const _CourseRosterTab({required this.students});

  final List<TutorStudent> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const TutorEmptyView(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có danh sách lớp',
        message: 'Backend hiện chưa trả về sinh viên cho khóa học này.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(child: Text(_initials(student.name))),
            title: Text(student.name),
            subtitle: Text(student.email),
          ),
        );
      },
    );
  }
}

String _contentTypeLabel(String type) => switch (type) {
  'introduction' => 'Giới thiệu',
  'material' => 'Tài liệu',
  'movie' => 'Video bài giảng',
  'note' => 'Bài tập',
  'submission' => 'Bài nộp',
  'reference' => 'Tài liệu tham khảo',
  'bookReference' => 'Sách tham khảo',
  _ => 'Nội dung khác',
};

IconData _contentIcon(String type) => switch (type) {
  'introduction' => Icons.info_outline_rounded,
  'material' => Icons.description_outlined,
  'movie' => Icons.play_circle_outline_rounded,
  'note' || 'submission' => Icons.assignment_outlined,
  'reference' || 'bookReference' => Icons.link_rounded,
  _ => Icons.article_outlined,
};

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
