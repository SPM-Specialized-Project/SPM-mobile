import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/auth_session.dart';
import '../../../learning/domain/course.dart';
import '../../../learning/presentation/member_profile_screen.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import 'student_course_feedback_screen.dart';
import 'student_course_analytics_screen.dart';
import 'student_codepulse_screen.dart';
import 'student_submissions_screen.dart';

class StudentCoursesScreen extends ConsumerStatefulWidget {
  const StudentCoursesScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<StudentCoursesScreen> createState() =>
      _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends ConsumerState<StudentCoursesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sort = 'Tên khóa học';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentCoursesProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentCoursesProvider),
      ),
      data: (courses) {
        final normalizedQuery = _query.trim().toLowerCase();
        final visibleCourses =
            courses
                .where(
                  (course) =>
                      normalizedQuery.isEmpty ||
                      course.title.toLowerCase().contains(normalizedQuery) ||
                      course.code.toLowerCase().contains(normalizedQuery) ||
                      course.instructor.toLowerCase().contains(normalizedQuery),
                )
                .toList(growable: false)
              ..sort((left, right) {
                final leftValue = switch (_sort) {
                  'Mã khóa học' => left.code,
                  'Giảng viên' => left.instructor,
                  _ => left.title,
                };
                final rightValue = switch (_sort) {
                  'Mã khóa học' => right.code,
                  'Giảng viên' => right.instructor,
                  _ => right.title,
                };
                return leftValue.toLowerCase().compareTo(
                  rightValue.toLowerCase(),
                );
              });
        return RefreshIndicator(
          onRefresh: () => ref.refresh(studentCoursesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _StudentWelcome(
                name: widget.session.user.firstName,
                courseCount: courses.length,
              ),
              const SizedBox(height: 24),
              Text(
                'Khóa học của tôi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Các khóa học mà tài khoản của bạn đang có quyền truy cập.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Tìm tên, mã hoặc giảng viên',
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Sắp xếp khóa học',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder: (_) => [
                      for (final option in [
                        'Tên khóa học',
                        'Mã khóa học',
                        'Giảng viên',
                      ])
                        PopupMenuItem(value: option, child: Text(option)),
                    ],
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sort_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
              else if (visibleCourses.isEmpty)
                const SizedBox(
                  height: 230,
                  child: TutorEmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'Không tìm thấy khóa học',
                    message: 'Thử tìm bằng tên khóa, mã hoặc tên giảng viên.',
                  ),
                )
              else
                for (var index = 0; index < visibleCourses.length; index++) ...[
                  _CourseCard(
                    course: visibleCourses[index],
                    index: index,
                    session: widget.session,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
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
  const _CourseCard({
    required this.course,
    required this.index,
    required this.session,
  });

  final Course course;
  final int index;
  final AuthSession session;

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
            builder: (_) => StudentCourseDetailScreen(
              courseId: course.id,
              session: session,
            ),
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
  const StudentCourseDetailScreen({
    required this.courseId,
    required this.session,
    super.key,
  });

  final String courseId;
  final AuthSession session;

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
        length: detail.course.code.toUpperCase().startsWith('DSA') ? 6 : 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              detail.course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'Nội dung'),
                const Tab(text: 'Danh sách lớp'),
                const Tab(text: 'Bài nộp'),
                const Tab(text: 'Tiến độ'),
                const Tab(text: 'Đánh giá'),
                if (detail.course.code.toUpperCase().startsWith('DSA'))
                  const Tab(text: 'Luyện code'),
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
                      _StudentCourseSection(section: section),
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
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => MemberProfileScreen(
                              memberId: student.id,
                              name: student.name,
                              email: student.email,
                              courseId: detail.course.id,
                              courseTitle: detail.course.title,
                              courseCode: detail.course.code,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              StudentSubmissionsScreen(courseId: detail.course.id),
              StudentCourseAnalyticsScreen(
                courseId: detail.course.id,
                courseTitle: detail.course.title,
              ),
              StudentCourseFeedbackScreen(
                courseId: detail.course.id,
                courseTitle: detail.course.title,
                instructor: detail.course.instructor,
                session: session,
              ),
              if (detail.course.code.toUpperCase().startsWith('DSA'))
                StudentCodePulseTab(courseId: detail.course.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCourseSection extends StatelessWidget {
  const _StudentCourseSection({required this.section});

  final CourseSection section;

  static const _labels = <String, String>{
    'introduction': 'Giới thiệu',
    'material': 'Tài liệu',
    'movie': 'Video bài giảng',
    'note': 'Bài tập',
    'submission': 'Nộp bài',
    'reference': 'Đường dẫn',
    'bookReference': 'Sách tham khảo',
  };

  @override
  Widget build(BuildContext context) {
    final data = section.data;
    final children = <Widget>[];

    if (section.type == 'introduction') {
      final text = data['text']?.toString() ?? section.description;
      if (text.isNotEmpty) children.add(SelectableText(text));
    } else if (section.type == 'submission') {
      if (section.description.isNotEmpty) {
        children.add(Text(section.description));
      }
      final dueDate = data['dueDate']?.toString() ?? '';
      children.add(Text('Hạn nộp: ${dueDate.isEmpty ? 'Chưa đặt' : dueDate}'));
      final maxFiles = data['maxFiles'] ?? 1;
      final allowedTypes = data['allowedTypes'];
      final typeLabel = allowedTypes is List && allowedTypes.isNotEmpty
          ? allowedTypes.join(', ')
          : 'chưa quy định';
      children.add(Text('Tối đa $maxFiles tệp · $typeLabel'));
    } else if (section.type == 'bookReference') {
      final books = data['books'];
      if (books is List) {
        for (final value in books) {
          if (value is! Map) continue;
          final title = value['name'] ?? value['title'] ?? 'Tài liệu';
          final author = value['author']?.toString();
          final source = value['url'] ?? value['source'];
          children.add(
            Text(
              [
                title.toString(),
                if (author != null && author.isNotEmpty) author,
                if (source != null && source.toString().isNotEmpty)
                  source.toString(),
              ].join('\n'),
            ),
          );
          children.add(const SizedBox(height: 10));
        }
      }
    } else {
      final key = switch (section.type) {
        'material' => 'document',
        'movie' => 'video',
        'note' => 'assignment',
        _ => 'link',
      };
      final nested = data[key];
      if (nested is Map) {
        final title = nested['title']?.toString();
        final description = nested['description']?.toString();
        final source = nested['url'] ?? nested['source'];
        final dueDate = nested['dueDate']?.toString();
        if (title != null && title.isNotEmpty) {
          children.add(
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          );
        }
        if (description != null && description.isNotEmpty) {
          children.add(Text(description));
        }
        if (source != null && source.toString().isNotEmpty) {
          children.add(SelectableText(source.toString()));
        }
        if (dueDate != null && dueDate.isNotEmpty) {
          children.add(Text('Hạn: $dueDate'));
        }
      }
    }

    if (children.isEmpty) {
      children.add(const Text('Chưa có nội dung chi tiết.'));
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[section.type] ?? 'Nội dung khác',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}
