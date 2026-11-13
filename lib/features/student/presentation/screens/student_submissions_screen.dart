import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/course_submission.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';

class StudentSubmissionsScreen extends ConsumerStatefulWidget {
  const StudentSubmissionsScreen({this.courseId, this.assignmentId, super.key});

  final String? courseId;
  final String? assignmentId;

  @override
  ConsumerState<StudentSubmissionsScreen> createState() =>
      _StudentSubmissionsScreenState();
}

class _StudentSubmissionsScreenState
    extends ConsumerState<StudentSubmissionsScreen> {
  String _assignmentFilter = '';

  @override
  void initState() {
    super.initState();
    _assignmentFilter = widget.assignmentId ?? '';
  }

  @override
  void didUpdateWidget(covariant StudentSubmissionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.assignmentId != widget.assignmentId) {
      _assignmentFilter = widget.assignmentId ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(studentSubmissionsProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentSubmissionsProvider),
      ),
      data: (submissions) {
        final scoped = widget.courseId == null
            ? submissions
            : submissions.where((item) => item.courseId == widget.courseId);
        final assignmentLabels = <String, String>{};
        for (final item in scoped) {
          final key = item.assignmentId.isEmpty
              ? 'title:${item.assignmentTitle}'
              : item.assignmentId;
          assignmentLabels.putIfAbsent(key, () => item.assignmentTitle);
        }
        final assignmentKeys = assignmentLabels.keys.toList()
          ..sort(
            (left, right) => assignmentLabels[left]!.toLowerCase().compareTo(
              assignmentLabels[right]!.toLowerCase(),
            ),
          );
        final selectedAssignment =
            assignmentLabels.containsKey(_assignmentFilter)
            ? _assignmentFilter
            : '';
        final sorted =
            [
              for (final item in scoped)
                if (selectedAssignment.isEmpty ||
                    (item.assignmentId.isEmpty
                            ? 'title:${item.assignmentTitle}'
                            : item.assignmentId) ==
                        selectedAssignment)
                  item,
            ]..sort(
              (a, b) => (b.submittedAt ?? DateTime(0)).compareTo(
                a.submittedAt ?? DateTime(0),
              ),
            );
        return RefreshIndicator(
          onRefresh: () => ref.refresh(studentSubmissionsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(
                selectedAssignment.isNotEmpty
                    ? 'Bài nộp · ${assignmentLabels[selectedAssignment]}'
                    : widget.courseId == null
                    ? 'Bài tập của tôi'
                    : 'Bài nộp trong khóa học',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Backend chỉ trả bài của tài khoản đang đăng nhập. Hiện ứng dụng nhận liên kết bài làm; chưa có API tải tệp lên.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (assignmentKeys.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedAssignment.isEmpty
                      ? '__all__'
                      : selectedAssignment,
                  decoration: const InputDecoration(
                    labelText: 'Bài tập',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '__all__',
                      child: Text('Tất cả bài tập'),
                    ),
                    for (final key in assignmentKeys)
                      DropdownMenuItem(
                        value: key,
                        child: Text(
                          assignmentLabels[key]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _assignmentFilter =
                        value == '__all__' || value == null ? '' : value,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (sorted.isEmpty)
                SizedBox(
                  height: 260,
                  child: TutorEmptyView(
                    icon: Icons.assignment_outlined,
                    title: selectedAssignment.isNotEmpty
                        ? 'Chưa có bài nộp cho bài tập này'
                        : 'Chưa có bài tập',
                    message: selectedAssignment.isNotEmpty
                        ? 'Bài tập này chưa có bản ghi bài nộp trong dữ liệu tài khoản.'
                        : 'Bài tập sẽ xuất hiện khi khóa học có assignment. Hãy thử đổi bộ lọc nếu danh sách đang bị thu hẹp.',
                  ),
                )
              else
                for (final submission in sorted) ...[
                  _SubmissionCard(
                    submission: submission,
                    onOpen: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => StudentSubmissionDetailScreen(
                          submissionId: submission.id,
                        ),
                      ),
                    ),
                    onSubmit: () => _openSubmitSheet(context, ref, submission),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSubmitSheet(
    BuildContext context,
    WidgetRef ref,
    CourseSubmission submission,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SubmitLinkSheet(submission: submission),
    );
    if (saved == true) ref.invalidate(studentSubmissionsProvider);
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.onOpen,
    required this.onSubmit,
  });

  final CourseSubmission submission;
  final VoidCallback onOpen;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    submission.assignmentTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TutorStatusPill(status: submission.status),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              submission.courseTitle,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (submission.score != null) ...[
              const SizedBox(height: 12),
              Text(
                'Điểm: ${submission.score}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (submission.feedback.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Nhận xét: ${submission.feedback}'),
            ],
            if (submission.fileUrl != null &&
                submission.fileUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Liên kết đã nộp: ${submission.fileUrl}',
                style: TextStyle(color: colors.primary),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Chi tiết'),
                ),
                if (submission.canSubmit && submission.canEdit)
                  OutlinedButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(
                      submission.submittedAt == null
                          ? 'Nộp bằng liên kết'
                          : 'Cập nhật bài nộp',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudentSubmissionDetailScreen extends ConsumerWidget {
  const StudentSubmissionDetailScreen({required this.submissionId, super.key});

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentSubmissionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài nộp')),
      body: state.when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(studentSubmissionsProvider),
        ),
        data: (items) {
          final matches = items.where((item) => item.id == submissionId);
          if (matches.isEmpty) {
            return const TutorEmptyView(
              icon: Icons.assignment_late_outlined,
              title: 'Không tìm thấy bài nộp',
              message: 'Bài nộp không còn trong dữ liệu tài khoản hiện tại.',
            );
          }
          final submission = matches.first;
          final localizations = MaterialLocalizations.of(context);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                submission.courseTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                submission.assignmentTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Trạng thái')),
                          TutorStatusPill(status: submission.status),
                        ],
                      ),
                      if (submission.termName != null ||
                          submission.classroomName != null) ...[
                        const Divider(height: 22),
                        if (submission.termName != null)
                          _SubmissionDetailRow(
                            label: 'Học kỳ',
                            value: submission.termName!,
                          ),
                        if (submission.classroomName != null) ...[
                          const SizedBox(height: 8),
                          _SubmissionDetailRow(
                            label: 'Lớp',
                            value: submission.classroomName!,
                          ),
                        ],
                      ],
                      if (submission.dueDate != null) ...[
                        const SizedBox(height: 10),
                        _SubmissionDetailRow(
                          label: 'Hạn nộp',
                          value: localizations.formatMediumDate(
                            submission.dueDate!.toLocal(),
                          ),
                        ),
                      ],
                      if (submission.submittedAt != null) ...[
                        const SizedBox(height: 10),
                        _SubmissionDetailRow(
                          label: 'Ngày nộp',
                          value: localizations.formatFullDate(
                            submission.submittedAt!.toLocal(),
                          ),
                        ),
                      ],
                      if (submission.score != null) ...[
                        const SizedBox(height: 10),
                        _SubmissionDetailRow(
                          label: 'Điểm',
                          value: '${submission.score!.toStringAsFixed(1)} / 10',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (submission.feedback.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhận xét của giảng viên',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(submission.feedback),
                      ],
                    ),
                  ),
                ),
              ],
              if (submission.fileUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liên kết đã nộp',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(submission.fileUrl!),
                        if (!_isWebUrl(submission.fileUrl!)) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Đường dẫn này không phải URL mở được từ thiết bị.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (submission.canSubmit && submission.canEdit) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => _SubmitLinkSheet(submission: submission),
                    );
                    if (saved == true) {
                      ref.invalidate(studentSubmissionsProvider);
                    }
                  },
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    submission.submittedAt == null
                        ? 'Nộp bài bằng liên kết'
                        : 'Cập nhật liên kết',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SubmissionDetailRow extends StatelessWidget {
  const _SubmissionDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

bool _isWebUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.host.isNotEmpty;
}

class _SubmitLinkSheet extends ConsumerStatefulWidget {
  const _SubmitLinkSheet({required this.submission});

  final CourseSubmission submission;

  @override
  ConsumerState<_SubmitLinkSheet> createState() => _SubmitLinkSheetState();
}

class _SubmitLinkSheetState extends ConsumerState<_SubmitLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _urlController = TextEditingController(
    text: widget.submission.fileUrl ?? '',
  );
  var _saving = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nộp bài bằng liên kết',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Ví dụ: liên kết Drive đã cấp quyền xem. Backend chưa cung cấp tải tệp trực tiếp.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Liên kết bài làm',
                hintText: 'https://…',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              validator: (value) {
                final uri = Uri.tryParse((value ?? '').trim());
                if (uri == null ||
                    !{'http', 'https'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
                  return 'Nhập một URL bắt đầu bằng http:// hoặc https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gửi bài'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uri = Uri.parse(_urlController.text.trim());
      await ref
          .read(studentRepositoryProvider)
          .submitLink(submissionId: widget.submission.id, fileUri: uri);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }
}
