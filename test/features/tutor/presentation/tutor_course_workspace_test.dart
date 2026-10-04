import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/app/theme/app_theme.dart';
import 'package:spm_mobile/features/tutor/application/tutor_providers.dart';
import 'package:spm_mobile/features/tutor/application/tutor_dsa_providers.dart';
import 'package:spm_mobile/features/tutor/data/tutor_repository.dart';
import 'package:spm_mobile/features/tutor/data/tutor_dsa_repository.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course_workspace.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_submission.dart';
import 'package:spm_mobile/features/tutor/presentation/screens/tutor_course_detail_screen.dart';

final _course = TutorCourse.fromJson({
  'id': '13',
  'code': 'DSA-LAB',
  'title': 'DSA LAB',
  'instructor': 'Tutor',
  'students': [
    {'id': 'student', 'name': 'Student One', 'email': 'student@example.com'},
  ],
});
const _section = TutorCourseSection(
  id: 'intro',
  type: 'introduction',
  title: 'Giới thiệu khóa học',
  data: {'text': 'Nội dung cũ'},
);

class _Repository extends TutorRepository {
  _Repository({this.canEdit = true}) : super(Dio());
  final bool canEdit;
  List<TutorCourseSection> sections = [_section];
  int revision = 0;
  TutorCourseFeedback feedback = const TutorCourseFeedback();
  int? savedRevision;
  @override
  Future<TutorCourseDetail> getCourseDetail(String id) async =>
      TutorCourseDetail(
        course: _course,
        sections: sections,
        canEdit: canEdit,
        contentRevision: revision,
      );
  @override
  Future<TutorCourseDetail> saveCourseContent(
    String id,
    List<TutorCourseSection> content,
    int expectedRevision,
  ) async {
    savedRevision = expectedRevision;
    sections = content;
    revision++;
    return getCourseDetail(id);
  }

  @override
  Future<CourseRoster> getRoster(String id) async => const CourseRoster(
    members: [
      CourseMember(
        id: 'member',
        name: 'Student One',
        email: 'student@example.com',
        status: 'ACTIVE',
        canEdit: true,
      ),
    ],
    availableStudents: [],
    canCreate: true,
  );
  @override
  Future<TutorCourseFeedback> getCourseFeedback(String id) async => feedback;
  @override
  Future<void> saveCourseFeedback(String id, TutorCourseFeedback value) async {
    feedback = TutorCourseFeedback(
      courseComment: value.courseComment,
      studentComments: value.studentComments,
      revision: value.revision + 1,
    );
  }

  @override
  Future<List<TutorSubmission>> getCourseSubmissions(
    TutorCourse course,
  ) async => [];
}

class _DsaRepository extends TutorDsaRepository {
  _DsaRepository() : super(Dio());
  @override
  Future<({List<CodePulseTerm> terms, List<CodePulseClassroom> classrooms})>
  getCatalog() async => (
    terms: [
      CodePulseTerm(
        id: 'term',
        courseId: '13',
        name: '2026 Semester 1',
        startDate: DateTime(2020),
        endDate: DateTime(2030),
        resetDate: DateTime(2030),
        status: 'ACTIVE',
      ),
    ],
    classrooms: [
      const CodePulseClassroom(
        id: 'class-1',
        courseId: '13',
        termId: 'term',
        name: 'CodePulse Demo',
        description: 'DSA classroom',
        status: 'ACTIVE',
        lecturerEmail: 'tutor@example.com',
        termName: '2026 Semester 1',
      ),
    ],
  );
  @override
  Future<DsaClassroomWorkspace> getWorkspace(String id) async =>
      const DsaClassroomWorkspace(assignments: [], versions: [], labs: []);
}

Future<void> _pump(WidgetTester tester, _Repository repository) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tutorRepositoryProvider.overrideWithValue(repository),
        tutorDsaRepositoryProvider.overrideWithValue(_DsaRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TutorCourseDetailScreen(courseId: '13'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('DSA course has all web tabs and edit permission controls', (
    tester,
  ) async {
    await _pump(tester, _Repository());
    for (final label in [
      'Tổng quan',
      'Danh sách lớp',
      'Đánh giá',
      'Terms and classrooms',
      'Bài nộp',
      'Xem thống kê',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Thêm danh mục'), findsNothing);
    await tester.tap(find.byTooltip('Chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm danh mục'), findsOneWidget);
    await tester.ensureVisible(find.text('Terms and classrooms').first);
    await tester.tap(find.text('Terms and classrooms').first);
    await tester.pumpAndSettle();
    expect(find.text('CodePulse Demo'), findsWidgets);
    expect(find.text('Bài tập mới'), findsOneWidget);
    expect(find.text('Tạo LAB mới'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'section edits save with the loaded revision and survive a new screen',
    (tester) async {
      final repository = _Repository();
      await _pump(tester, repository);
      await tester.tap(find.byTooltip('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sửa Giới thiệu khóa học'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Giới thiệu mới',
      );
      await tester.ensureVisible(find.text('Áp dụng thay đổi'));
      await tester.tap(find.text('Áp dụng thay đổi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu nội dung'));
      await tester.pumpAndSettle();
      expect(repository.savedRevision, 0);
      expect(repository.sections.single.title, 'Giới thiệu mới');
      expect(repository.sections.single.data['text'], 'Nội dung cũ');
      expect(find.text('Lưu nội dung'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, repository);
      expect(find.text('Giới thiệu mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'course without edit permission does not expose mutation controls',
    (tester) async {
      await _pump(tester, _Repository(canEdit: false));
      expect(find.byTooltip('Chỉnh sửa'), findsNothing);
      expect(find.text('Thêm danh mục'), findsNothing);
      expect(find.byTooltip('Sửa Giới thiệu khóa học'), findsNothing);
    },
  );

  testWidgets('tutor feedback saves a separate comment per active student', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await tester.tap(find.byTooltip('Chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đánh giá').first);
    await tester.tap(find.text('Đánh giá').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Có tiến bộ');
    await tester.enterText(find.byType(TextField).last, 'Môn học hữu ích');
    await tester.tap(find.text('Lưu đánh giá'));
    await tester.pumpAndSettle();
    expect(
      repository.feedback.studentComments['student@example.com'],
      'Có tiến bộ',
    );
    expect(repository.feedback.courseComment, 'Môn học hữu ích');
    expect(repository.feedback.revision, 1);
    expect(tester.takeException(), isNull);
  });
}
