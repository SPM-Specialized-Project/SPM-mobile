import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_session.dart';
import '../../admin/presentation/screens/admin_codepulse_screen.dart';
import '../../management/presentation/screens/course_requests_screen.dart';
import '../../management/presentation/screens/manager_courses_screen.dart';
import '../../management/presentation/screens/manager_registrations_screen.dart';
import '../../management/presentation/screens/manager_sessions_screen.dart';
import '../../tutor/presentation/screens/tutor_courses_screen.dart';
import '../../tutor/presentation/screens/tutor_registrations_screen.dart';
import '../../tutor/presentation/screens/tutor_sessions_screen.dart';
import '../../tutor/presentation/screens/tutor_submissions_screen.dart';
import '../../student/presentation/screens/student_courses_screen.dart';
import '../../student/presentation/screens/student_registrations_screen.dart';
import '../../student/presentation/screens/student_sessions_screen.dart';
import '../../student/presentation/screens/student_submissions_screen.dart';
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
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(_initials(widget.session.user.name)),
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
    if (widget.session.role == UserRole.student) {
      return switch (destination.section) {
        AppSection.courses => StudentCoursesScreen(session: widget.session),
        AppSection.sessions => const StudentSessionsScreen(),
        AppSection.submissions => const StudentSubmissionsScreen(),
        AppSection.registrations => StudentRegistrationsScreen(
          session: widget.session,
        ),
        _ => _DestinationPage(
          destination: destination,
          session: widget.session,
        ),
      };
    }
    if (widget.session.role == UserRole.lecturer) {
      return switch (destination.section) {
        AppSection.courses => TutorCoursesScreen(session: widget.session),
        AppSection.sessions => TutorSessionsScreen(session: widget.session),
        AppSection.submissions => const TutorSubmissionsScreen(),
        AppSection.registrations => TutorRegistrationsScreen(
          session: widget.session,
        ),
        _ => _DestinationPage(
          destination: destination,
          session: widget.session,
        ),
      };
    }
    if (widget.session.role == UserRole.coordinator ||
        widget.session.role == UserRole.chairman) {
      return switch (destination.section) {
        AppSection.courses => const ManagerCoursesScreen(),
        AppSection.sessions => ManagerSessionsScreen(session: widget.session),
        AppSection.registrations => const ManagerRegistrationsScreen(),
        AppSection.courseRequests => CourseRequestsScreen(
          session: widget.session,
        ),
        _ => _DestinationPage(
          destination: destination,
          session: widget.session,
        ),
      };
    }
    if (widget.session.role == UserRole.admin) {
      return switch (destination.section) {
        AppSection.courses => const ManagerCoursesScreen(),
        AppSection.codePulse => const AdminCodePulseScreen(),
        _ => _DestinationPage(
          destination: destination,
          session: widget.session,
        ),
      };
    }
    return _DestinationPage(destination: destination, session: widget.session);
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

class _DestinationPage extends StatelessWidget {
  const _DestinationPage({required this.destination, required this.session});

  final AppDestination destination;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (destination.section == AppSection.profile) {
      return _ProfilePage(session: session);
    }

    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Icon(_iconFor(destination.icon), size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xin chào, ${session.user.name}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  destination.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Chip(label: Text(destination.apiHint)),
                const SizedBox(height: 12),
                Text(
                  'Đây là khung màn hình của phase đầu tiên. Bước kế tiếp '
                  'sẽ nối repository và hiển thị dữ liệu thật từ backend.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    DestinationIcon.sessions => Icons.event_note_rounded,
    DestinationIcon.submissions => Icons.assignment_turned_in_rounded,
    DestinationIcon.registrations => Icons.fact_check_rounded,
    DestinationIcon.courseRequests => Icons.library_add_check_rounded,
    DestinationIcon.codePulse => Icons.code_rounded,
    DestinationIcon.profile => Icons.person_outline_rounded,
  };
}
