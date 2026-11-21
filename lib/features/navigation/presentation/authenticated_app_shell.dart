import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_session.dart';
import '../../admin/presentation/screens/admin_codepulse_screen.dart';
import '../../backend_status/presentation/backend_status_screen.dart';
import '../../management/presentation/screens/course_requests_screen.dart';
import '../../management/presentation/screens/manager_courses_screen.dart';
import '../../management/presentation/screens/manager_registrations_screen.dart';
import '../../management/presentation/screens/manager_matching_screen.dart';
import '../../management/presentation/screens/manager_sessions_screen.dart';
import '../../management/presentation/screens/manager_reports_screen.dart';
import '../../management/presentation/screens/manager_statistics_overview_screen.dart';
import '../../management/presentation/screens/session_history_screen.dart';
import '../../management/presentation/screens/session_requests_screen.dart';
import '../../tutor/presentation/screens/tutor_courses_screen.dart';
import '../../tutor/presentation/screens/tutor_registrations_screen.dart';
import '../../tutor/presentation/screens/tutor_sessions_screen.dart';
import '../../tutor/presentation/screens/tutor_submissions_screen.dart';
import '../../student/presentation/screens/student_courses_screen.dart';
import '../../student/presentation/screens/student_registrations_screen.dart';
import '../../student/presentation/screens/student_sessions_screen.dart';
import '../../student/presentation/screens/student_session_request_screen.dart';
import '../../student/presentation/screens/student_submissions_screen.dart';
import '../../assistant/presentation/assistant_screen.dart';
import '../../assistant/data/assistant_knowledge.dart';
import '../../communication/presentation/communication_status_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../domain/role_navigation.dart';
import '../../tssa/presentation/tssa_screen.dart';

class AuthenticatedAppShell extends ConsumerStatefulWidget {
  const AuthenticatedAppShell({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<AuthenticatedAppShell> createState() =>
      _AuthenticatedAppShellState();
}

class _AuthenticatedAppShellState extends ConsumerState<AuthenticatedAppShell> {
  var _selectedIndex = 0;
  late List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.role != widget.session.role) {
      _selectedIndex = 0;
      _initializePages();
    }
  }

  void _initializePages() {
    final destinations = destinationsForRole(widget.session.role);
    _pages = List<Widget?>.filled(destinations.length, null);
    _pages[0] = _destinationPage(destinations[0]);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = destinationsForRole(widget.session.role);
    final colors = Theme.of(context).colorScheme;
    final selectedDestination = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedDestination.label),
        actions: [
          if ([
            UserRole.student,
            UserRole.lecturer,
          ].contains(widget.session.role))
            IconButton(
              tooltip: 'Trợ lý hướng dẫn có nguồn',
              icon: const Icon(Icons.question_answer_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssistantScreen(
                    role: widget.session.role,
                    onOpenDestination: _openAssistantDestination,
                  ),
                ),
              ),
            ),
          if (widget.session.role != UserRole.unknown)
            IconButton(
              tooltip: 'Hỗ trợ học tập TSSA',
              icon: const Icon(Icons.diversity_1_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TssaScreen()),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Tài khoản',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Tài khoản')),
                    body: _ProfilePage(session: widget.session),
                  ),
                ),
              ),
              icon: CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(_initials(widget.session.user.name)),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final page in _pages) page ?? const SizedBox.shrink()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _pages[index] ??= _destinationPage(destinations[index]);
          });
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(_iconFor(destination.icon)),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  Widget _destinationPage(AppDestination destination) {
    return switch (destination.section) {
      AppSection.courses => switch (widget.session.role) {
        UserRole.student => StudentCoursesScreen(session: widget.session),
        UserRole.lecturer => TutorCoursesScreen(session: widget.session),
        UserRole.coordinator ||
        UserRole.chairman ||
        UserRole.admin => const ManagerCoursesScreen(),
        _ => const _RoleUnavailablePage(feature: 'Khóa học'),
      },
      AppSection.schedule => switch (widget.session.role) {
        UserRole.student => StudentSessionsScreen(session: widget.session),
        UserRole.lecturer => TutorSessionsScreen(session: widget.session),
        UserRole.coordinator ||
        UserRole.chairman => ManagerSessionsScreen(session: widget.session),
        UserRole.admin => const _RoleUnavailablePage(feature: 'Lịch học'),
        _ => const _RoleUnavailablePage(feature: 'Lịch học'),
      },
      AppSection.library => const LibraryScreen(),
      AppSection.more => _MoreScreen(
        session: widget.session,
        onOpenDestination: _openAssistantDestination,
      ),
    };
  }

  void _openAssistantDestination(AssistantDestination destination) {
    final section = switch (destination) {
      AssistantDestination.courses => AppSection.courses,
      AssistantDestination.schedule => AppSection.schedule,
      AssistantDestination.library => AppSection.library,
      AssistantDestination.more => AppSection.more,
    };
    final destinations = destinationsForRole(widget.session.role);
    final index = destinations.indexWhere((item) => item.section == section);
    if (index < 0) return;
    Navigator.of(context).pop();
    setState(() {
      _selectedIndex = index;
      _pages[index] ??= _destinationPage(destinations[index]);
    });
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({required this.session, required this.onOpenDestination});

  final AuthSession session;
  final ValueChanged<AssistantDestination> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    final items = switch (session.role) {
      UserRole.student => <_MoreItem>[
        _MoreItem(
          icon: Icons.history_rounded,
          title: 'Lịch sử buổi học',
          subtitle: 'Xem các buổi đã lưu trong lịch.',
          page: (_) => const SessionHistoryScreen(),
        ),
        _MoreItem(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Bài nộp',
          subtitle: 'Theo dõi bài đã nộp và trạng thái chấm.',
          page: (_) => const StudentSubmissionsScreen(),
        ),
        _MoreItem(
          icon: Icons.fact_check_outlined,
          title: 'Đăng ký hỗ trợ',
          subtitle: 'Xem yêu cầu đăng ký của bạn.',
          page: (_) => StudentRegistrationsScreen(session: session),
        ),
        _MoreItem(
          icon: Icons.event_available_outlined,
          title: 'Yêu cầu buổi học',
          subtitle: 'Tạo yêu cầu học bù hoặc thay đổi lịch.',
          page: (_) => StudentSessionRequestScreen(ownerId: session.user.email),
        ),
      ],
      UserRole.lecturer => <_MoreItem>[
        _MoreItem(
          icon: Icons.history_rounded,
          title: 'Lịch sử buổi học',
          subtitle: 'Xem các buổi đã lưu trong lịch.',
          page: (_) => const SessionHistoryScreen(),
        ),
        _MoreItem(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Bài nộp',
          subtitle: 'Xem và phản hồi bài của khóa được phân công.',
          page: (_) => const TutorSubmissionsScreen(),
        ),
        _MoreItem(
          icon: Icons.fact_check_outlined,
          title: 'Hồ sơ giảng dạy',
          subtitle: 'Theo dõi hồ sơ đăng ký tutor.',
          page: (_) => TutorRegistrationsScreen(session: session),
        ),
        _MoreItem(
          icon: Icons.event_note_outlined,
          title: 'Yêu cầu buổi học',
          subtitle: 'Xem và phản hồi yêu cầu thuộc khóa được phân công.',
          page: (_) => const SessionRequestsScreen(),
        ),
      ],
      UserRole.coordinator || UserRole.chairman => <_MoreItem>[
        _MoreItem(
          icon: Icons.history_rounded,
          title: 'Lịch sử buổi học',
          subtitle: 'Xem các buổi đã lưu trong lịch.',
          page: (_) => const SessionHistoryScreen(),
        ),
        _MoreItem(
          icon: Icons.fact_check_outlined,
          title: 'Đăng ký',
          subtitle: 'Xem danh sách đăng ký theo quyền quản lý.',
          page: (_) => const ManagerRegistrationsScreen(),
        ),
        _MoreItem(
          icon: Icons.library_add_check_outlined,
          title: 'Yêu cầu môn học',
          subtitle: 'Xem và xử lý yêu cầu khóa học.',
          page: (_) => CourseRequestsScreen(session: session),
        ),
        _MoreItem(
          icon: Icons.compare_arrows_rounded,
          title: 'Ghép lớp',
          subtitle: 'Đối chiếu tiêu chí hồ sơ, không tự tạo phân công.',
          page: (_) => const ManagerMatchingScreen(),
        ),
        _MoreItem(
          icon: Icons.bar_chart_rounded,
          title: 'Thống kê theo khóa học',
          subtitle: 'Xem buổi học gần nhất và mở báo cáo từng khóa.',
          page: (_) => const ManagerStatisticsOverviewScreen(),
        ),
        _MoreItem(
          icon: Icons.analytics_outlined,
          title: 'Báo cáo hoạt động',
          subtitle: 'Tổng hợp khóa học, lịch và hồ sơ API trả về.',
          page: (_) => const ManagerReportsScreen(),
        ),
        _MoreItem(
          icon: Icons.event_note_outlined,
          title: 'Yêu cầu buổi học',
          subtitle: 'Xem và xử lý yêu cầu do sinh viên gửi.',
          page: (_) => const SessionRequestsScreen(),
        ),
      ],
      UserRole.admin => <_MoreItem>[
        _MoreItem(
          icon: Icons.code_rounded,
          title: 'Quản lý CodePulse',
          subtitle: 'Quản lý học kỳ và lớp DSA theo quyền admin.',
          page: (_) => const AdminCodePulseScreen(),
        ),
        _MoreItem(
          icon: Icons.monitor_heart_outlined,
          title: 'Giám sát hệ thống',
          subtitle: 'Kiểm tra kết nối API; chưa có số liệu tài nguyên máy chủ.',
          page: (_) => const BackendStatusScreen(),
        ),
      ],
      _ => const <_MoreItem>[],
    };
    if (session.role != UserRole.unknown) {
      items.addAll([
        _MoreItem(
          icon: Icons.notifications_none_rounded,
          title: 'Thông báo',
          subtitle: 'Thông tin về phạm vi đồng bộ mobile.',
          page: (_) => CommunicationStatusScreen(
            feature: CommunicationFeature.notifications,
            ownerId: session.user.email,
            role: session.role,
          ),
        ),
        _MoreItem(
          icon: Icons.forum_outlined,
          title: 'Tin nhắn',
          subtitle: 'Trao đổi chưa có dịch vụ hội thoại trên mobile.',
          page: (_) => CommunicationStatusScreen(
            feature: CommunicationFeature.chat,
            ownerId: session.user.email,
            role: session.role,
          ),
        ),
      ]);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            'Tiện ích',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Các mục dành cho vai trò ${_roleLabel(session.role)}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    ListTile(
                      leading: Icon(items[index].icon),
                      title: Text(items[index].title),
                      subtitle: Text(items[index].subtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: items[index].page),
                      ),
                    ),
                    if (index != items.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          if ([UserRole.student, UserRole.lecturer].contains(session.role))
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: const Text('Trợ lý hướng dẫn'),
                subtitle: const Text('Tra cứu hướng dẫn kèm nguồn tham khảo.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AssistantScreen(
                      role: session.role,
                      onOpenDestination: onOpenDestination,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder page;
}

class _RoleUnavailablePage extends StatelessWidget {
  const _RoleUnavailablePage({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: _UnavailableFeatureCard(
      icon: Icons.lock_outline_rounded,
      title: 'Bạn chưa có quyền xem $feature',
      message: 'Tài khoản hiện tại chưa được cấp quyền cho mục này.',
    ),
  );
}

class _UnavailableFeatureCard extends StatelessWidget {
  const _UnavailableFeatureCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colors.surfaceContainerHighest,
                foregroundColor: colors.onSurfaceVariant,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.student => 'sinh viên',
  UserRole.lecturer => 'giảng viên',
  UserRole.coordinator => 'điều phối viên',
  UserRole.chairman => 'chủ nhiệm',
  UserRole.admin => 'quản trị viên',
  _ => 'tài khoản',
};

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: Text(
              session.user.name.isEmpty
                  ? '?'
                  : session.user.name.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            session.user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(session.user.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Vai trò do backend cấp'),
              subtitle: Text(session.role.name),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).logout();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể xóa phiên đăng nhập khỏi thiết bị.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(DestinationIcon icon) {
  return switch (icon) {
    DestinationIcon.courses => Icons.menu_book_rounded,
    DestinationIcon.schedule => Icons.event_note_rounded,
    DestinationIcon.library => Icons.auto_stories_outlined,
    DestinationIcon.more => Icons.grid_view_rounded,
  };
}
