import '../../auth/data/auth_session.dart';

enum AppSection { courses, schedule, library, more }

enum DestinationIcon { courses, schedule, library, more }

class AppDestination {
  const AppDestination({
    required this.section,
    required this.label,
    required this.icon,
  });

  final AppSection section;
  final String label;
  final DestinationIcon icon;
}

const _stableDestinations = <AppDestination>[
  AppDestination(
    section: AppSection.courses,
    label: 'Khóa học',
    icon: DestinationIcon.courses,
  ),
  AppDestination(
    section: AppSection.schedule,
    label: 'Lịch',
    icon: DestinationIcon.schedule,
  ),
  AppDestination(
    section: AppSection.library,
    label: 'Thư viện',
    icon: DestinationIcon.library,
  ),
  AppDestination(
    section: AppSection.more,
    label: 'Thêm',
    icon: DestinationIcon.more,
  ),
];

/// The shell stays stable across roles; feature access is still enforced by
/// backend permissions and role-aware entries inside More.
List<AppDestination> destinationsForRole(UserRole role) => _stableDestinations;
