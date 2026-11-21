import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/management_providers.dart';
import '../../data/management_models.dart';
import 'manager_course_detail_screen.dart';
import '../widgets/management_common.dart';

class ManagerReportsScreen extends ConsumerStatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  ConsumerState<ManagerReportsScreen> createState() =>
      _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends ConsumerState<ManagerReportsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(managerCoursesProvider.future),
      ref.refresh(managerSessionsProvider.future),
      ref.refresh(managerRegistrationsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(managerCoursesProvider);
    final sessionsState = ref.watch(managerSessionsProvider);
    final registrationsState = ref.watch(managerRegistrationsProvider);

    if (coursesState.isLoading ||
        sessionsState.isLoading ||
        registrationsState.isLoading) {
      return const ManagementLoading();
    }

    final error =
        coursesState.error ?? sessionsState.error ?? registrationsState.error;
    if (error != null) {
      return ManagementError(
        message: managementErrorMessage(error),
        onRetry: () {
          ref.invalidate(managerCoursesProvider);
          ref.invalidate(managerSessionsProvider);
          ref.invalidate(managerRegistrationsProvider);
        },
      );
    }

    final courses = coursesState.value ?? const [];
    final sessions = sessionsState.value ?? const [];
    final registrations = registrationsState.value ?? const [];
    final pending = registrations
        .where((item) => item.status.toLowerCase() == 'pending')
        .length;
    final approved = registrations
        .where((item) => item.status.toLowerCase() == 'approved')
        .length;
    final declined = registrations
        .where(
          (item) =>
              {'declined', 'rejected'}.contains(item.status.toLowerCase()),
        )
        .length;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredCourses = courses
        .where(
          (course) =>
              normalizedQuery.isEmpty ||
              course.title.toLowerCase().contains(normalizedQuery) ||
              course.code.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          const ManagementPageHeader(
            title: 'Báo cáo hoạt động',
            subtitle: 'Tổng hợp từ khóa học, lịch và đăng ký backend trả về.',
          ),
          const _ReportScopeNotice(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: columns == 2 ? 1.55 : 1.4,
                children: [
                  _MetricCard(
                    label: 'Khóa học',
                    value: courses.length,
                    icon: Icons.menu_book_outlined,
                  ),
                  _MetricCard(
                    label: 'Buổi học',
                    value: sessions.length,
                    icon: Icons.event_note_outlined,
                  ),
                  _MetricCard(
                    label: 'Đang chờ',
                    value: pending,
                    icon: Icons.hourglass_top_rounded,
                  ),
                  _MetricCard(
                    label: 'Đã xử lý',
                    value: approved + declined,
                    icon: Icons.fact_check_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Theo khóa học',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Tìm tên hoặc mã khóa học',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (filteredCourses.isEmpty)
            const ManagementEmpty(
              title: 'Không có khóa học phù hợp',
              message: 'Thử từ khóa khác hoặc tải lại dữ liệu.',
            )
          else
            for (final course in filteredCourses) ...[
              _CourseReportCard(
                course: course,
                sessionCount: sessions
                    .where((item) => item.courseId == course.id)
                    .length,
                registrations: registrations
                    .where(
                      (item) => item.subjects.any(
                        (subject) => subject.id == course.id,
                      ),
                    )
                    .length,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ManagerCourseReportScreen(
                      course: course,
                      sessionCount: sessions
                          .where((item) => item.courseId == course.id)
                          .length,
                      registrations: registrations
                          .where(
                            (item) => item.subjects.any(
                              (subject) => subject.id == course.id,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class ManagerCourseReportScreen extends StatelessWidget {
  const ManagerCourseReportScreen({
    required this.course,
    required this.sessionCount,
    required this.registrations,
    super.key,
  });

  final ManagedCourse course;
  final int sessionCount;
  final List<ManagedRegistration> registrations;

  @override
  Widget build(BuildContext context) {
    final pending = registrations
        .where((item) => item.status.toLowerCase() == 'pending')
        .length;
    final approved = registrations
        .where((item) => item.status.toLowerCase() == 'approved')
        .length;
    final declined = registrations
        .where(
          (item) =>
              {'declined', 'rejected'}.contains(item.status.toLowerCase()),
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo khóa học')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Text(
            course.code,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Giảng viên: ${course.instructor}'),
          const SizedBox(height: 14),
          const _ReportScopeNotice(),
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
                  _MetricCard(
                    label: 'Thành viên',
                    value: course.students.length,
                    icon: Icons.people_outline_rounded,
                  ),
                  _MetricCard(
                    label: 'Buổi học',
                    value: sessionCount,
                    icon: Icons.event_note_outlined,
                  ),
                  _MetricCard(
                    label: 'Đăng ký liên quan',
                    value: registrations.length,
                    icon: Icons.how_to_reg_outlined,
                  ),
                  _MetricCard(
                    label: 'Đang chờ',
                    value: pending,
                    icon: Icons.hourglass_top_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Trạng thái đăng ký',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _ReportStatusRow(label: 'Đang chờ', value: pending),
                const Divider(height: 1),
                _ReportStatusRow(label: 'Đã duyệt', value: approved),
                const Divider(height: 1),
                _ReportStatusRow(label: 'Từ chối', value: declined),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ManagerCourseDetailScreen(courseId: course.id),
              ),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Mở chi tiết khóa học'),
          ),
        ],
      ),
    );
  }
}

class _ReportStatusRow extends StatelessWidget {
  const _ReportStatusRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Text(
      '$value',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _ReportScopeNotice extends StatelessWidget {
  const _ReportScopeNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Các số liệu là số bản ghi hiện được API trả về cho tài khoản. Chưa có API tổng hợp điểm, đánh giá hoặc lịch sử theo kỳ; màn hình không ước tính các chỉ số đó.',
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseReportCard extends StatelessWidget {
  const _CourseReportCard({
    required this.course,
    required this.sessionCount,
    required this.registrations,
    required this.onTap,
  });

  final ManagedCourse course;
  final int sessionCount;
  final int registrations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maximum = [
      course.students.length,
      sessionCount,
      registrations,
      1,
    ].reduce((a, b) => a > b ? a : b);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 3),
              Text('${course.code} · ${course.instructor}'),
              const SizedBox(height: 14),
              _CourseMetricBar(
                label: 'Thành viên',
                value: course.students.length,
                maximum: maximum,
                color: colors.primary,
              ),
              const SizedBox(height: 10),
              _CourseMetricBar(
                label: 'Buổi học',
                value: sessionCount,
                maximum: maximum,
                color: colors.tertiary,
              ),
              const SizedBox(height: 10),
              _CourseMetricBar(
                label: 'Đăng ký liên quan',
                value: registrations,
                maximum: maximum,
                color: colors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseMetricBar extends StatelessWidget {
  const _CourseMetricBar({
    required this.label,
    required this.value,
    required this.maximum,
    required this.color,
  });

  final String label;
  final int value;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 132, child: Text(label)),
      Expanded(
        child: LinearProgressIndicator(
          value: value / maximum,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.end)),
    ],
  );
}
