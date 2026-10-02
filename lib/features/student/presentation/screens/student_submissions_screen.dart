import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/course_submission.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';

class StudentSubmissionsScreen extends ConsumerWidget {
  const StudentSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentSubmissionsProvider);
    return state.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentSubmissionsProvider),
      ),
      data: (submissions) {
        final sorted = [...submissions]
          ..sort(
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
                'Bài tập của tôi',
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
              if (sorted.isEmpty)
                const SizedBox(
                  height: 260,
                  child: TutorEmptyView(
                    icon: Icons.assignment_outlined,
                    title: 'Chưa có bài tập',
                    message: 'Bài tập sẽ xuất hiện khi khóa học có assignment.',
                  ),
                )
              else
                for (final submission in sorted) ...[
                  _SubmissionCard(
                    submission: submission,
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
  const _SubmissionCard({required this.submission, required this.onSubmit});

  final CourseSubmission submission;
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
            if (submission.submittedAt == null ||
                submission.status != 'graded') ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    submission.submittedAt == null
                        ? 'Nộp bằng liên kết'
                        : 'Cập nhật bài nộp',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
