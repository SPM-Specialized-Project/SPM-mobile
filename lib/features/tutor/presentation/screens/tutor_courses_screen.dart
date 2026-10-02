import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/auth_session.dart';
import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../widgets/tutor_ui.dart';
import 'tutor_course_detail_screen.dart';

class TutorCoursesScreen extends ConsumerStatefulWidget {
  const TutorCoursesScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<TutorCoursesScreen> createState() => _TutorCoursesScreenState();
}

class _TutorCoursesScreenState extends ConsumerState<TutorCoursesScreen> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(tutorCoursesProvider);

    return coursesState.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(tutorCoursesProvider),
      ),
      data: (courses) => _buildCourseList(courses),
    );
  }

  Widget _buildCourseList(List<TutorCourse> courses) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredCourses = courses
        .where((course) {
          return normalizedQuery.isEmpty ||
              course.title.toLowerCase().contains(normalizedQuery) ||
              course.code.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    final studentCount = courses.fold<int>(
      0,
      (total, course) => total + course.students.length,
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(tutorCoursesProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          TutorBrandHero(
            name: widget.session.user.firstName,
            courseCount: courses.length,
            studentCount: studentCount,
          ),
          const SizedBox(height: 26),
          TutorPageHeading(
            title: 'Khóa học của tôi',
            subtitle: 'Các lớp được backend phân công cho tài khoản này.',
            trailing: Icon(
              Icons.menu_book_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã môn',
              prefixIcon: const Icon(Icons.search_rounded),
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
          const SizedBox(height: 16),
          if (filteredCourses.isEmpty)
            SizedBox(
              height: 250,
              child: TutorEmptyView(
                icon: courses.isEmpty
                    ? Icons.school_outlined
                    : Icons.search_off_rounded,
                title: courses.isEmpty
                    ? 'Chưa có khóa học được phân công'
                    : 'Không tìm thấy khóa học',
                message: courses.isEmpty
                    ? 'Khi backend phân công lớp cho bạn, lớp sẽ xuất hiện tại đây.'
                    : 'Thử tìm bằng một phần tên môn hoặc mã môn.',
              ),
            )
          else
            for (var index = 0; index < filteredCourses.length; index++) ...[
              _TutorCourseCard(
                course: filteredCourses[index],
                imageAsset: _courseImage(filteredCourses[index].id, index),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TutorCourseDetailScreen(
                      courseId: filteredCourses[index].id,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _TutorCourseCard extends StatelessWidget {
  const _TutorCourseCard({
    required this.course,
    required this.imageAsset,
    required this.onTap,
  });

  final TutorCourse course;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: AppTheme.primaryColor),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.66),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  const Positioned(
                    right: 14,
                    top: 14,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.people_alt_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${course.students.length} sinh viên',
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

String _courseImage(String courseId, int fallbackIndex) {
  final courseNumber = int.tryParse(courseId);
  final index = courseNumber == null
      ? fallbackIndex % 3
      : (courseNumber - 1).abs() % 3;
  return switch (index) {
    0 => 'assets/course_cards/course_blue.png',
    1 => 'assets/course_cards/course_red.png',
    _ => 'assets/course_cards/course_green.png',
  };
}
