import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../../domain/tutor_course_workspace.dart';
import '../../domain/tutor_submission.dart';
import 'tutor_ui.dart';

class TutorCourseRosterTab extends ConsumerStatefulWidget {
  const TutorCourseRosterTab({
    required this.courseId,
    required this.editable,
    super.key,
  });
  final String courseId;
  final bool editable;
  @override
  ConsumerState<TutorCourseRosterTab> createState() => _RosterState();
}

class _RosterState extends ConsumerState<TutorCourseRosterTab> {
  bool _saving = false;
  Future<void> _change(Future<void> Function() operation) async {
    setState(() => _saving = true);
    try {
      await operation();
      ref.invalidate(tutorCourseRosterProvider(widget.courseId));
      ref.invalidate(tutorCourseDetailProvider(widget.courseId));
      ref.invalidate(tutorCoursesProvider);
      ref.invalidate(tutorCourseSubmissionsProvider(widget.courseId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(tutorCourseRosterProvider(widget.courseId))
      .when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () =>
              ref.invalidate(tutorCourseRosterProvider(widget.courseId)),
        ),
        data: (roster) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(tutorCourseRosterProvider(widget.courseId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              TutorPageHeading(
                title: 'Danh sách lớp',
                subtitle:
                    '${roster.members.where((m) => m.status == 'ACTIVE').length} sinh viên đang tham gia',
              ),
              const SizedBox(height: 16),
              if (!widget.editable && roster.canCreate)
                const Text(
                  'Bật Chỉnh sửa để thêm, thu hồi hoặc kích hoạt lại sinh viên.',
                ),
              if (widget.editable && roster.canCreate)
                OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final email = await showDialog<String>(
                            context: context,
                            builder: (_) => _AddMemberDialog(roster: roster),
                          );
                          if (email != null) {
                            await _change(
                              () => ref
                                  .read(tutorRepositoryProvider)
                                  .addCourseMember(widget.courseId, email),
                            );
                          }
                        },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm sinh viên'),
                ),
              if (roster.members.isEmpty)
                const TutorEmptyView(
                  icon: Icons.people_outline,
                  title: 'Chưa có sinh viên',
                  message: 'Thêm tài khoản sinh viên vào danh sách lớp.',
                ),
              for (final member in roster.members)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SelectableText(member.email),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.status == 'ACTIVE'
                                    ? 'Đang tham gia'
                                    : 'Đã thu hồi',
                              ),
                            ),
                            if (widget.editable && member.canEdit)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        if (member.status == 'ACTIVE') {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Thu hồi quyền tham gia?',
                                                  ),
                                                  content: Text(member.name),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Thu hồi',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                          if (confirmed == true) {
                                            await _change(
                                              () => ref
                                                  .read(tutorRepositoryProvider)
                                                  .revokeCourseMember(
                                                    widget.courseId,
                                                    member.id,
                                                  ),
                                            );
                                          }
                                        } else {
                                          await _change(
                                            () => ref
                                                .read(tutorRepositoryProvider)
                                                .addCourseMember(
                                                  widget.courseId,
                                                  member.email,
                                                ),
                                          );
                                        }
                                      },
                                child: Text(
                                  member.status == 'ACTIVE'
                                      ? 'Thu hồi'
                                      : 'Kích hoạt lại',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.roster});
  final CourseRoster roster;
  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final active = widget.roster.members
        .where((m) => m.status == 'ACTIVE')
        .map((m) => m.email.toLowerCase())
        .toSet();
    final candidates = widget.roster.availableStudents
        .where(
          (s) =>
              !active.contains((s['email'] as String).toLowerCase()) &&
              '${s['name']} ${s['email']}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
    return AlertDialog(
      title: const Text('Thêm sinh viên'),
      content: SizedBox(
        width: 400,
        height: 360,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm tên hoặc email',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(child: Text('Không có tài khoản phù hợp.'))
                  : ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(candidates[i]['name'] as String),
                        subtitle: Text(candidates[i]['email'] as String),
                        onTap: () =>
                            Navigator.pop(context, candidates[i]['email']),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class TutorCourseFeedbackTab extends ConsumerWidget {
  const TutorCourseFeedbackTab({
    required this.course,
    required this.editable,
    super.key,
  });
  final TutorCourse course;
  final bool editable;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(tutorCourseFeedbackProvider(course.id))
      .when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(tutorCourseFeedbackProvider(course.id)),
        ),
        data: (feedback) => _FeedbackForm(
          course: course,
          feedback: feedback,
          editable: editable,
        ),
      );
}

class _FeedbackForm extends ConsumerStatefulWidget {
  const _FeedbackForm({
    required this.course,
    required this.feedback,
    required this.editable,
  });
  final TutorCourse course;
  final TutorCourseFeedback feedback;
  final bool editable;
  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm>
    with AutomaticKeepAliveClientMixin {
  late final _courseComment = TextEditingController(
    text: widget.feedback.courseComment,
  );
  final _comments = <String, TextEditingController>{};
  late int _revision = widget.feedback.revision;
  bool _saving = false;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _courseComment.dispose();
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(tutorRepositoryProvider)
          .saveCourseFeedback(
            widget.course.id,
            TutorCourseFeedback(
              courseComment: _courseComment.text,
              revision: _revision,
              studentComments: {
                for (final student in widget.course.students)
                  student.email:
                      _comments[student.email]?.text ??
                      widget.feedback.studentComments[student.email] ??
                      '',
              },
            ),
          );
      _revision += 1;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá')));
      }
      ref.invalidate(tutorCourseFeedbackProvider(widget.course.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const TutorPageHeading(
          title: 'Đánh giá',
          subtitle: 'Nhận xét từng sinh viên và môn học.',
        ),
        const SizedBox(height: 16),
        if (!widget.editable)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Bật Chỉnh sửa để cập nhật nhận xét.'),
          ),
        for (final student in widget.course.students)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _comments.putIfAbsent(
                student.email,
                () => TextEditingController(
                  text: widget.feedback.studentComments[student.email] ?? '',
                ),
              ),
              readOnly: !widget.editable || _saving,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Nhận xét về ${student.name}',
                helperText: student.email,
              ),
            ),
          ),
        TextField(
          controller: _courseComment,
          readOnly: !widget.editable || _saving,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Nhận xét về môn học'),
        ),
        if (widget.editable)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu đánh giá'),
            ),
          ),
      ],
    );
  }
}

class TutorCourseStatisticsTab extends ConsumerWidget {
  const TutorCourseStatisticsTab({required this.course, super.key});
  final TutorCourse course;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(tutorCourseSubmissionsProvider(course.id))
      .when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () =>
              ref.invalidate(tutorCourseSubmissionsProvider(course.id)),
        ),
        data: (submissions) {
          final received = submissions
              .where((s) => s.submittedAt != null)
              .length;
          final graded = submissions.where((s) => s.score != null).toList();
          final average = graded.isEmpty
              ? null
              : graded.fold<double>(0, (sum, s) => sum + s.score!) /
                    graded.length;
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(tutorCourseSubmissionsProvider(course.id).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const TutorPageHeading(
                  title: 'Xem thống kê',
                  subtitle: 'Tổng hợp từ bài nộp hiện có trong môn.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      label: 'Sinh viên',
                      value: '${course.students.length}',
                    ),
                    _Metric(label: 'Đã nộp', value: '$received'),
                    _Metric(label: 'Đã chấm', value: '${graded.length}'),
                    _Metric(
                      label: 'Điểm TB / 10',
                      value: average?.toStringAsFixed(1) ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Theo sinh viên',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final student in course.students)
                  _StudentStats(
                    student: student,
                    submissions: submissions
                        .where(
                          (s) =>
                              s.studentEmail.toLowerCase() ==
                              student.email.toLowerCase(),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    ),
  );
}

class _StudentStats extends StatelessWidget {
  const _StudentStats({required this.student, required this.submissions});
  final TutorStudent student;
  final List<TutorSubmission> submissions;
  @override
  Widget build(BuildContext context) {
    final scores = submissions
        .where((s) => s.score != null)
        .map((s) => s.score!)
        .toList();
    final average = scores.isEmpty
        ? 'Chưa có điểm'
        : 'TB ${(scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1)} / 10';
    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(student.name),
        subtitle: Text(
          '${student.email}\n${submissions.where((s) => s.submittedAt != null).length} bài đã nộp · $average',
        ),
        isThreeLine: true,
      ),
    );
  }
}
