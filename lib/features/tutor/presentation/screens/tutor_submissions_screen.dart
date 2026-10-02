import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tutor_providers.dart';
import '../../domain/tutor_submission.dart';
import '../widgets/tutor_ui.dart';

enum _SubmissionFilter { all, waiting, graded }

class TutorSubmissionsScreen extends ConsumerStatefulWidget {
  const TutorSubmissionsScreen({super.key});

  @override
  ConsumerState<TutorSubmissionsScreen> createState() =>
      _TutorSubmissionsScreenState();
}

class _TutorSubmissionsScreenState
    extends ConsumerState<TutorSubmissionsScreen> {
  _SubmissionFilter _filter = _SubmissionFilter.all;
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionsState = ref.watch(tutorSubmissionsProvider);
    return submissionsState.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(tutorSubmissionsProvider),
      ),
      data: _buildList,
    );
  }

  Widget _buildList(List<TutorSubmission> submissions) {
    final waitingCount = submissions
        .where((item) => item.status == 'submitted')
        .length;
    final normalizedQuery = _query.trim().toLowerCase();
    final visible = submissions
        .where((item) {
          final matchesFilter = switch (_filter) {
            _SubmissionFilter.all => true,
            _SubmissionFilter.waiting => item.status == 'submitted',
            _SubmissionFilter.graded => item.status == 'graded',
          };
          final matchesSearch =
              normalizedQuery.isEmpty ||
              item.studentName.toLowerCase().contains(normalizedQuery) ||
              item.assignmentTitle.toLowerCase().contains(normalizedQuery) ||
              item.courseTitle.toLowerCase().contains(normalizedQuery);
          return matchesFilter && matchesSearch;
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .refresh(tutorSubmissionsProvider.future)
                .then<void>((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              TutorPageHeading(
                title: 'Bài cần chấm',
                subtitle: waitingCount == 0
                    ? 'Bài nộp của sinh viên trong các lớp được giao.'
                    : '$waitingCount bài đang chờ bạn xem.',
                trailing: _PendingCount(count: waitingCount),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Tìm sinh viên, bài tập hoặc môn học',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Xóa tìm kiếm',
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    selected: _filter == _SubmissionFilter.all,
                    onSelected: () =>
                        setState(() => _filter = _SubmissionFilter.all),
                  ),
                  _FilterChip(
                    label: 'Chờ chấm',
                    selected: _filter == _SubmissionFilter.waiting,
                    onSelected: () =>
                        setState(() => _filter = _SubmissionFilter.waiting),
                  ),
                  _FilterChip(
                    label: 'Đã chấm',
                    selected: _filter == _SubmissionFilter.graded,
                    onSelected: () =>
                        setState(() => _filter = _SubmissionFilter.graded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                SizedBox(
                  height: 260,
                  child: TutorEmptyView(
                    icon: submissions.isEmpty
                        ? Icons.assignment_outlined
                        : Icons.filter_alt_off_outlined,
                    title: submissions.isEmpty
                        ? 'Chưa có bài nộp'
                        : 'Không có kết quả phù hợp',
                    message: submissions.isEmpty
                        ? 'Các bài tập của khóa học được phân công sẽ hiện ở đây.'
                        : 'Đổi bộ lọc hoặc từ khóa tìm kiếm để xem các bài khác.',
                  ),
                )
              else
                for (final submission in visible) ...[
                  _TutorSubmissionCard(
                    submission: submission,
                    onGrade: () => _openGradeSheet(submission),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGradeSheet(TutorSubmission submission) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _GradeSubmissionSheet(submission: submission),
    );
    if (saved == true) {
      ref.invalidate(tutorSubmissionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu điểm và nhận xét.')));
    }
  }
}

class _PendingCount extends StatelessWidget {
  const _PendingCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 22,
      backgroundColor: count > 0
          ? colors.errorContainer
          : colors.primaryContainer,
      foregroundColor: count > 0 ? colors.onErrorContainer : colors.primary,
      child: Text(
        '$count',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _TutorSubmissionCard extends StatelessWidget {
  const _TutorSubmissionCard({required this.submission, required this.onGrade});

  final TutorSubmission submission;
  final VoidCallback onGrade;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNotSubmitted = submission.status == 'not-submitted';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
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
            const SizedBox(height: 6),
            Text(
              submission.courseTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.primary,
                  child: Text(_initials(submission.studentName)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        submission.studentEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (submission.score != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.grade_outlined, color: colors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Điểm: ${submission.score!.toStringAsFixed(1)} / 10',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
            if (submission.fileUrl != null &&
                submission.fileUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      submission.fileUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (submission.feedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                submission.feedback,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (!isNotSubmitted) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onGrade,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    submission.score == null ? 'Chấm bài' : 'Sửa điểm',
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

class _GradeSubmissionSheet extends ConsumerStatefulWidget {
  const _GradeSubmissionSheet({required this.submission});

  final TutorSubmission submission;

  @override
  ConsumerState<_GradeSubmissionSheet> createState() =>
      _GradeSubmissionSheetState();
}

class _GradeSubmissionSheetState extends ConsumerState<_GradeSubmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _scoreController = TextEditingController(
    text: widget.submission.score?.toString() ?? '',
  );
  late final _feedbackController = TextEditingController(
    text: widget.submission.feedback,
  );
  var _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(tutorRepositoryProvider)
          .gradeSubmission(
            submissionId: widget.submission.id,
            score: double.parse(_scoreController.text.trim()),
            feedback: _feedbackController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = tutorErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nhận xét bài làm',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.submission.studentName} · ${widget.submission.assignmentTitle}',
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Điểm',
                  hintText: '0–10',
                  suffixText: '/ 10',
                ),
                validator: (value) {
                  final score = double.tryParse(value?.trim() ?? '');
                  if (score == null) {
                    return 'Nhập điểm dạng số.';
                  }
                  if (score < 0 || score > 10) {
                    return 'Điểm phải trong khoảng 0–10.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét',
                  hintText: 'Ghi rõ điểm tốt và nội dung cần cải thiện...',
                  alignLabelWithHint: true,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu điểm và nhận xét'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
