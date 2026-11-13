import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/management_providers.dart';
import 'manager_course_detail_screen.dart';
import '../widgets/management_common.dart';

class ManagerCoursesScreen extends ConsumerStatefulWidget {
  const ManagerCoursesScreen({super.key});

  @override
  ConsumerState<ManagerCoursesScreen> createState() =>
      _ManagerCoursesScreenState();
}

class _ManagerCoursesScreenState extends ConsumerState<ManagerCoursesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sort = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(managerCoursesProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(managerCoursesProvider),
      ),
      data: (courses) {
        final query = _query.trim().toLowerCase();
        final visibleCourses =
            courses
                .where(
                  (course) =>
                      query.isEmpty ||
                      course.title.toLowerCase().contains(query) ||
                      course.code.toLowerCase().contains(query) ||
                      course.instructor.toLowerCase().contains(query),
                )
                .toList()
              ..sort((left, right) {
                final leftValue = _sort == 'code' ? left.code : left.title;
                final rightValue = _sort == 'code' ? right.code : right.title;
                return leftValue.toLowerCase().compareTo(
                  rightValue.toLowerCase(),
                );
              });

        return RefreshIndicator(
          onRefresh: () => ref.refresh(managerCoursesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const ManagementPageHeader(
                title: 'Danh mục khóa học',
                subtitle:
                    'Danh sách khóa học backend cấp theo quyền của tài khoản hiện tại.',
              ),
              if (courses.isNotEmpty) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: 'Tìm khóa học',
                    hintText: 'Tên, mã môn hoặc giảng viên',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${visibleCourses.length} / ${courses.length} khóa học',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sort,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Tên A–Z')),
                        DropdownMenuItem(value: 'code', child: Text('Mã A–Z')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _sort = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (courses.isEmpty)
                const SizedBox(
                  height: 250,
                  child: ManagementEmpty(
                    title: 'Chưa có khóa học',
                    message: 'Backend chưa trả khóa học nào cho tài khoản này.',
                  ),
                )
              else if (visibleCourses.isEmpty)
                const SizedBox(
                  height: 220,
                  child: ManagementEmpty(
                    title: 'Không tìm thấy khóa học',
                    message: 'Thử tìm theo tên, mã môn hoặc giảng viên khác.',
                  ),
                )
              else
                for (final course in visibleCourses) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ManagerCourseDetailScreen(courseId: course.id),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: const Icon(Icons.menu_book_rounded),
                      ),
                      title: Text(
                        course.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${course.code} · ${course.instructor}\n${course.students.length} thành viên · ${course.assignmentCount} bài tập',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}
