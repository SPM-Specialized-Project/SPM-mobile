import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/management_providers.dart';
import '../widgets/management_common.dart';

class ManagerCoursesScreen extends ConsumerWidget {
  const ManagerCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerCoursesProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(managerCoursesProvider),
      ),
      data: (courses) => RefreshIndicator(
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
            if (courses.isEmpty)
              const SizedBox(
                height: 250,
                child: ManagementEmpty(
                  title: 'Chưa có khóa học',
                  message: 'Backend chưa trả khóa học nào cho tài khoản này.',
                ),
              )
            else
              for (final course in courses) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: ListTile(
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
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
