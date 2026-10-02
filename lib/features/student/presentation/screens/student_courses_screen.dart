import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/auth_session.dart';
import '../../../learning/domain/course.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';

class StudentCoursesScreen extends ConsumerWidget {
  const StudentCoursesScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentCoursesProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentCoursesProvider),
      ),
      data: (courses) => RefreshIndicator(
        onRefresh: () => ref.refresh(studentCoursesProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _StudentWelcome(
              name: session.user.firstName,
              courseCount: courses.length,
            ),
            const SizedBox(height: 24),
            Text(
              'Khóa học của tôi',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Các khóa học mà tài khoản của bạn đang có quyền truy cập.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const SizedBox(
                height: 250,
                child: TutorEmptyView(
                  icon: Icons.school_outlined,
                  title: 'Chưa có khóa học',
                  message:
                      'Khóa học sẽ xuất hiện sau khi tài khoản có membership đang hoạt động.',
                ),
              )
            else
              for (var index = 0; index < courses.length; index++) ...[
                _CourseCard(course: courses[index], index: index),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _StudentWelcome extends StatelessWidget {
  const _StudentWelcome({required this.name, required this.courseCount});

  final String name;
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF4968FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KHÔNG GIAN HỌC TẬP',
            style: TextStyle(
              color: Color(0xFFDCE4FF),
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chào ${name.isEmpty ? 'bạn' : name}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$courseCount khóa học đang truy cập',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.index});

  final Course course;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = switch (index % 3) {
      0 => 'assets/course_cards/course_blue.png',
      1 => 'assets/course_cards/course_red.png',
      _ => 'assets/course_cards/course_green.png',
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentCourseDetailScreen(courseId: course.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 126,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: colors.primary),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      course.instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${course.assignmentCount} bài tập',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentCourseDetailScreen extends ConsumerWidget {
  const StudentCourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentCourseDetailProvider(courseId));
    return state.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: const TutorLoadingView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khóa học')),
        body: TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(studentCourseDetailProvider(courseId)),
        ),
      ),
      data: (detail) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              detail.course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Nội dung'),
                Tab(text: 'Danh sách lớp'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    detail.course.code,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Giảng viên: ${detail.course.instructor}'),
                  const SizedBox(height: 20),
                  Text(
                    'Nội dung khóa học',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (detail.sections.isEmpty)
                    const TutorEmptyView(
                      icon: Icons.menu_book_outlined,
                      title: 'Chưa có nội dung',
                      message:
                          'Backend chưa cung cấp nội dung cho khóa học này.',
                    )
                  else
                    for (final section in detail.sections)
                      Card(
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(section.title),
                          subtitle: Text(section.type),
                        ),
                      ),
                ],
              ),
              if (detail.course.students.isEmpty)
                const TutorEmptyView(
                  icon: Icons.people_outline_rounded,
                  title: 'Danh sách lớp trống',
                  message: 'Chưa có danh sách thành viên được trả về.',
                )
              else
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: detail.course.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = detail.course.students[index];
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            student.name.isEmpty
                                ? '?'
                                : student.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: Text(student.email),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
