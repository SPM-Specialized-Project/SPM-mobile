/// Presentation-only examples copied from the frontend's mock course catalog.
/// These are not authoritative course records and are not loaded from the API.
class CourseCardExample {
  const CourseCardExample({
    required this.title,
    required this.code,
    required this.backgroundAsset,
  });

  final String title;
  final String code;
  final String backgroundAsset;
}

const courseCardExamples = <CourseCardExample>[
  CourseCardExample(
    title: 'Computer Network',
    code: '79748_CO2013_003183_CLC',
    backgroundAsset: 'assets/course_cards/course_blue.png',
  ),
  CourseCardExample(
    title: 'Database System',
    code: '79748_CO2013_003184_CLC',
    backgroundAsset: 'assets/course_cards/course_red.png',
  ),
  CourseCardExample(
    title: 'Operating System',
    code: '79748_CO2013_003185_CLC',
    backgroundAsset: 'assets/course_cards/course_green.png',
  ),
];

/// Labels currently shown in the frontend's common sidebar.
const frontendModuleNames = <String>[
  'Khóa học của tôi',
  'Đăng ký môn học',
  'Lịch sử đăng ký',
  'Thư viện',
  'Lịch học',
];
