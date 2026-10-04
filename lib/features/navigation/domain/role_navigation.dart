import '../../auth/data/auth_session.dart';

enum AppSection {
  courses,
  sessions,
  submissions,
  registrations,
  courseRequests,
  codePulse,
  profile,
}

enum DestinationIcon {
  courses,
  sessions,
  submissions,
  registrations,
  courseRequests,
  codePulse,
  profile,
}

class AppDestination {
  const AppDestination({
    required this.section,
    required this.label,
    required this.icon,
    required this.description,
    required this.apiHint,
  });

  final AppSection section;
  final String label;
  final DestinationIcon icon;
  final String description;
  final String apiHint;
}

const _courses = AppDestination(
  section: AppSection.courses,
  label: 'Khóa học',
  icon: DestinationIcon.courses,
  description: 'Xem các khóa học mà tài khoản hiện tại được phép truy cập.',
  apiHint: 'GET /api/courses',
);

const _sessions = AppDestination(
  section: AppSection.sessions,
  label: 'Buổi học',
  icon: DestinationIcon.sessions,
  description: 'Theo dõi lịch học và các buổi hỗ trợ thuộc phạm vi của bạn.',
  apiHint: 'GET /api/sessions',
);

const _studentSessions = AppDestination(
  section: AppSection.sessions,
  label: 'Lịch học',
  icon: DestinationIcon.sessions,
  description: 'Theo dõi các buổi học thuộc những khóa bạn đang tham gia.',
  apiHint: 'GET /api/sessions',
);

const _submissions = AppDestination(
  section: AppSection.submissions,
  label: 'Bài nộp',
  icon: DestinationIcon.submissions,
  description:
      'Sinh viên xem bài của mình; lecturer xem bài của khóa được phân công.',
  apiHint: 'GET /api/courses/{courseId}/submissions',
);

const _registrations = AppDestination(
  section: AppSection.registrations,
  label: 'Đăng ký',
  icon: DestinationIcon.registrations,
  description: 'Xem đăng ký theo quyền của student, lecturer hoặc cấp quản lý.',
  apiHint: 'GET /api/registrations',
);

const _courseRequests = AppDestination(
  section: AppSection.courseRequests,
  label: 'Yêu cầu môn',
  icon: DestinationIcon.courseRequests,
  description: 'Khu vực yêu cầu khóa học dành cho coordinator và chairman.',
  apiHint: 'GET /api/course-requests',
);

const _codePulse = AppDestination(
  section: AppSection.codePulse,
  label: 'CodePulse',
  icon: DestinationIcon.codePulse,
  description:
      'Khu vực DSA Lab/CodePulse; backend có chính sách riêng cho admin.',
  apiHint: '/api/codepulse/terms và /api/codepulse/classrooms',
);

const _profile = AppDestination(
  section: AppSection.profile,
  label: 'Tài khoản',
  icon: DestinationIcon.profile,
  description: 'Thông tin lấy từ AuthSession vừa nhận khi đăng nhập.',
  apiHint: 'Dữ liệu đang có trong phiên đăng nhập',
);

const _tutorCourses = AppDestination(
  section: AppSection.courses,
  label: 'Lớp dạy',
  icon: DestinationIcon.courses,
  description: 'Các khóa học backend đã phân công cho tutor.',
  apiHint: 'GET /api/courses',
);

const _tutorSessions = AppDestination(
  section: AppSection.sessions,
  label: 'Lịch dạy',
  icon: DestinationIcon.sessions,
  description: 'Các buổi học do tutor sở hữu và buổi mới có thể tạo.',
  apiHint: 'GET, POST /api/sessions',
);

const _tutorSubmissions = AppDestination(
  section: AppSection.submissions,
  label: 'Bài nộp',
  icon: DestinationIcon.submissions,
  description: 'Xem bài nộp trong khóa được giao và gửi điểm, nhận xét.',
  apiHint: 'GET /api/courses/{courseId}/submissions',
);

const _tutorRegistrations = AppDestination(
  section: AppSection.registrations,
  label: 'Hồ sơ tutor',
  icon: DestinationIcon.registrations,
  description: 'Tạo và xem hồ sơ đăng ký hỗ trợ dạy kèm.',
  apiHint: 'GET, POST /api/registrations?registrationType=tutor',
);

/// Chỉ quyết định tab nào được hiển thị; backend vẫn là nơi kiểm tra quyền thật.
List<AppDestination> destinationsForRole(UserRole role) {
  return switch (role) {
    UserRole.student => [
      _courses,
      _studentSessions,
      _submissions,
      _registrations,
      _profile,
    ],
    UserRole.lecturer => [
      _tutorCourses,
      _tutorSessions,
      _tutorSubmissions,
      _tutorRegistrations,
      _profile,
    ],
    UserRole.coordinator || UserRole.chairman => [
      _courses,
      _sessions,
      _registrations,
      _courseRequests,
      _profile,
    ],
    UserRole.admin => [_courses, _codePulse, _profile],
    UserRole.unknown ||
    UserRole.tssaLearner ||
    UserRole.tssaGuardian ||
    UserRole.tssaTutor => [_profile],
  };
}
