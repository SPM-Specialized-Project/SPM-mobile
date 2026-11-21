import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/draft_storage.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import '../../data/student_codepulse_repository.dart';

class StudentCodePulseTab extends ConsumerStatefulWidget {
  const StudentCodePulseTab({required this.courseId, super.key});

  final String courseId;

  @override
  ConsumerState<StudentCodePulseTab> createState() =>
      _StudentCodePulseTabState();
}

class _StudentCodePulseTabState extends ConsumerState<StudentCodePulseTab> {
  String? _selectedClassroomId;

  @override
  Widget build(BuildContext context) {
    final classroomsState = ref.watch(
      studentCodePulseClassroomsProvider(widget.courseId),
    );
    return classroomsState.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () =>
            ref.invalidate(studentCodePulseClassroomsProvider(widget.courseId)),
      ),
      data: (classrooms) {
        if (classrooms.isEmpty) {
          return const TutorEmptyView(
            icon: Icons.code_rounded,
            title: 'Chưa có lớp CodePulse',
            message:
                'Lớp sẽ xuất hiện khi tài khoản có membership đang hoạt động trong học kỳ hiện tại.',
          );
        }
        final selected =
            classrooms
                .where((item) => item.id == _selectedClassroomId)
                .firstOrNull ??
            classrooms.first;
        final workState = ref.watch(
          studentCodePulseClassroomWorkProvider(selected.id),
        );

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(
                studentCodePulseClassroomsProvider(widget.courseId).future,
              ),
              ref.refresh(
                studentCodePulseClassroomWorkProvider(selected.id).future,
              ),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Text(
                'Luyện tập CodePulse',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                'Chọn lớp để xem các bài đã được giảng viên mở.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                decoration: const InputDecoration(
                  labelText: 'Lớp học',
                  prefixIcon: Icon(Icons.groups_2_outlined),
                ),
                items: [
                  for (final classroom in classrooms)
                    DropdownMenuItem(
                      value: classroom.id,
                      child: Text(
                        classroom.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedClassroomId = value);
                  }
                },
              ),
              if (selected.termName?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  selected.termName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              workState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 36),
                  child: TutorLoadingView(),
                ),
                error: (error, _) => TutorErrorView(
                  message: tutorErrorMessage(error),
                  onRetry: () => ref.invalidate(
                    studentCodePulseClassroomWorkProvider(selected.id),
                  ),
                ),
                data: (work) =>
                    _CodePulseWorkSections(classroom: selected, work: work),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CodePulseWorkSections extends StatelessWidget {
  const _CodePulseWorkSections({required this.classroom, required this.work});

  final StudentCodePulseClassroom classroom;
  final StudentCodePulseClassroomWork work;

  @override
  Widget build(BuildContext context) {
    final labAssignmentIds = work.labs
        .expand((lab) => lab.assignments)
        .map((assignment) => assignment.assignmentId)
        .toSet();
    final individualAssignments = work.assignments
        .where((assignment) => !labAssignmentIds.contains(assignment.id))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Bài tập cá nhân',
          subtitle: 'Tự luyện và nộp để hệ thống chấm bài.',
        ),
        if (individualAssignments.isEmpty)
          const _InlineEmptyState(
            message: 'Chưa có bài tập cá nhân được publish.',
          )
        else
          for (
            var index = 0;
            index < individualAssignments.length;
            index++
          ) ...[
            _PracticeAssignmentCard(
              classroom: classroom,
              assignment: individualAssignments[index],
              index: index,
            ),
            if (index != individualAssignments.length - 1)
              const SizedBox(height: 10),
          ],
        const SizedBox(height: 22),
        _SectionHeading(
          title: 'Bài tập trong LAB',
          subtitle: 'Thời hạn mở bài do giảng viên thiết lập.',
        ),
        if (work.labs.isEmpty)
          const _InlineEmptyState(message: 'Lớp chưa có buổi LAB nào.')
        else
          for (var index = 0; index < work.labs.length; index++) ...[
            _LabCard(classroom: classroom, lab: work.labs[index]),
            if (index != work.labs.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.classroom, required this.lab});

  final StudentCodePulseClassroom classroom;
  final StudentCodePulseLab lab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lab.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (lab.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          lab.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                      if (lab.startAt != null || lab.endAt != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          _labSchedule(context, lab),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LabStatusLabel(status: lab.status),
              ],
            ),
            if (lab.assignments.isNotEmpty) ...[
              const Divider(height: 22),
              for (var index = 0; index < lab.assignments.length; index++) ...[
                _LabAssignmentRow(
                  classroom: classroom,
                  lab: lab,
                  assignment: lab.assignments[index],
                  index: index,
                ),
                if (index != lab.assignments.length - 1)
                  const Divider(height: 18),
              ],
            ] else ...[
              const SizedBox(height: 10),
              const _InlineEmptyState(message: 'LAB chưa có bài tập.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabAssignmentRow extends StatelessWidget {
  const _LabAssignmentRow({
    required this.classroom,
    required this.lab,
    required this.assignment,
    required this.index,
  });

  final StudentCodePulseClassroom classroom;
  final StudentCodePulseLab lab;
  final StudentCodePulseLabAssignment assignment;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final codeAssignment = StudentCodePulseAssignment(
      id: assignment.assignmentId,
      classroomId: classroom.id,
      title: assignment.title,
      description: assignment.description,
      runtime: assignment.runtime,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentCodePulseWorkspaceScreen(
            classroom: classroom,
            assignment: codeAssignment,
            lab: lab,
            labAssignment: assignment,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _RuntimeLabel(runtime: assignment.runtime),
                      const SizedBox(width: 8),
                      _PracticeAccessLabel(access: assignment.practiceAccess),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PracticeAssignmentCard extends StatelessWidget {
  const _PracticeAssignmentCard({
    required this.classroom,
    required this.assignment,
    required this.index,
  });

  final StudentCodePulseClassroom classroom;
  final StudentCodePulseAssignment assignment;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentCodePulseWorkspaceScreen(
              classroom: classroom,
              assignment: assignment,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.primary,
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (assignment.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        assignment.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    _RuntimeLabel(runtime: assignment.runtime),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuntimeLabel extends StatelessWidget {
  const _RuntimeLabel({required this.runtime});

  final String runtime;

  @override
  Widget build(BuildContext context) {
    final label = switch (runtime.toUpperCase()) {
      'CPP' => 'C++',
      'PYTHON' => 'Python',
      _ => runtime,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _LabStatusLabel extends StatelessWidget {
  const _LabStatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status.toUpperCase()) {
      'LIVE' => 'Đang diễn ra',
      'PAUSED' => 'Tạm dừng',
      'ENDED' => 'Đã kết thúc',
      'CANCELLED' => 'Đã hủy',
      _ => 'Sắp diễn ra',
    };
    final active = status.toUpperCase() == 'LIVE';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE5F5EC) : const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? const Color(0xFF137547) : const Color(0xFF58636A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PracticeAccessLabel extends StatelessWidget {
  const _PracticeAccessLabel({required this.access});

  final String access;

  @override
  Widget build(BuildContext context) {
    final open = access.toUpperCase() == 'OPEN';
    return Text(
      open ? 'Đang mở' : 'Chưa mở / đã đóng',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: open ? const Color(0xFF137547) : const Color(0xFF58636A),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PracticeWindowNotice extends StatelessWidget {
  const _PracticeWindowNotice({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_practiceReasonLabel(reason)}. Lưu, chạy và nộp bài sẽ mở khi practice window được bật.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _labSchedule(BuildContext context, StudentCodePulseLab lab) {
  final localizations = MaterialLocalizations.of(context);
  final start = lab.startAt?.toLocal();
  final end = lab.endAt?.toLocal();
  if (start != null && end != null) {
    return '${localizations.formatMediumDate(start)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start))}–'
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end))}';
  }
  if (start != null) return localizations.formatMediumDate(start);
  if (end != null) return localizations.formatMediumDate(end);
  return '';
}

String? _optionalPracticeReason(Map<String, dynamic>? window) {
  final reason = window?['practiceAccessReason'];
  return reason is String ? reason : null;
}

String _practiceReasonLabel(String? reason) => switch (reason) {
  'NOT_OPEN_YET' => 'Practice window chưa mở',
  'EXPIRED' => 'Practice window đã hết hạn',
  'MANUALLY_CLOSED' => 'Giảng viên đã đóng practice window',
  'TERM_INACTIVE' => 'Học kỳ không còn hiệu lực',
  'CLASSROOM_ARCHIVED' => 'Lớp đã được lưu trữ',
  'INVALID_WINDOW' => 'Thời gian mở bài chưa hợp lệ',
  _ => 'Bài hiện chưa thể thao tác',
};

class StudentCodePulseWorkspaceScreen extends ConsumerStatefulWidget {
  const StudentCodePulseWorkspaceScreen({
    required this.classroom,
    required this.assignment,
    this.lab,
    this.labAssignment,
    super.key,
  });

  final StudentCodePulseClassroom classroom;
  final StudentCodePulseAssignment assignment;
  final StudentCodePulseLab? lab;
  final StudentCodePulseLabAssignment? labAssignment;

  @override
  ConsumerState<StudentCodePulseWorkspaceScreen> createState() =>
      _StudentCodePulseWorkspaceScreenState();
}

class _StudentCodePulseWorkspaceScreenState
    extends ConsumerState<StudentCodePulseWorkspaceScreen> {
  static const _draftForm = 'codepulse-source';

  final _codeController = TextEditingController();
  final _draftStorage = DraftStorage();
  Timer? _draftTimer;
  StudentCodePulseWorkspace? _workspace;
  Map<String, dynamic>? _runResult;
  StudentCodePulseSubmission? _submission;
  Object? _loadError;
  bool _loading = true;
  bool _saving = false;
  bool _running = false;
  bool _submitting = false;
  bool _practiceOpen = true;
  bool _hasLocalDraft = false;
  String? _revealingHintId;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _loadWorkspace();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (_workspace != null) unawaited(_persistLocalDraft());
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspace() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final workspace = await ref
          .read(studentCodePulseRepositoryProvider)
          .getWorkspace(
            classroomId: widget.classroom.id,
            assignmentId: widget.assignment.id,
            labId: widget.lab?.id,
            labAssignmentId: widget.labAssignment?.id,
          );
      if (!mounted) return;
      _workspace = workspace;
      _runResult = workspace.executionResult;
      final access = workspace.practiceWindow?['practiceAccess'];
      _practiceOpen = widget.labAssignment == null
          ? true
          : access is String
          ? access == 'OPEN'
          : widget.labAssignment!.practiceAccess == 'OPEN';
      final cached = await _readLocalDraft(workspace.id);
      if (!mounted) return;
      final cachedCode = cached?['sourceCode'];
      final rawCachedAt = cached?['draftAt'];
      final cachedAt = rawCachedAt is String
          ? DateTime.tryParse(rawCachedAt)
          : null;
      final remoteAt = workspace.updatedAt;
      final restoreLocalDraft =
          cachedCode is String &&
          cachedCode != workspace.sourceCode &&
          (remoteAt == null || cachedAt == null || cachedAt.isAfter(remoteAt));
      _hasLocalDraft = restoreLocalDraft;
      _codeController.text = restoreLocalDraft
          ? cachedCode
          : workspace.sourceCode.isNotEmpty
          ? workspace.sourceCode
          : (widget.assignment.starterCode ?? _defaultStarterCode());
      if (!restoreLocalDraft && cached != null) {
        await _removeLocalDraft(workspace.id);
      }
    } catch (error) {
      if (mounted) _loadError = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _defaultStarterCode() => switch (widget.assignment.runtime
      .toUpperCase()) {
    'CPP' =>
      '#include <iostream>\nusing namespace std;\n\nint main() {\n    return 0;\n}\n',
    _ => '# Viết lời giải của bạn tại đây\n',
  };

  Future<void> _save() async {
    final workspace = _workspace;
    if (workspace == null || _saving) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(studentCodePulseRepositoryProvider)
          .saveWorkspace(
            workspaceId: workspace.id,
            sourceCode: _codeController.text,
          );
      if (!mounted) return;
      _draftTimer?.cancel();
      await _removeLocalDraft(workspace.id);
      if (!mounted) return;
      setState(() {
        _workspace = saved;
        _hasLocalDraft = false;
      });
      _showMessage(_savedMessage(saved));
    } catch (error) {
      if (mounted) _showMessage(tutorErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _run() async {
    final workspace = _workspace;
    if (workspace == null || _running) return;
    if (_codeController.text.trim().isEmpty) {
      _showMessage('Nhập code trước khi chạy.');
      return;
    }
    setState(() => _running = true);
    try {
      final result = await ref
          .read(studentCodePulseRepositoryProvider)
          .runCode(workspaceId: workspace.id, sourceCode: _codeController.text);
      if (!mounted) return;
      _draftTimer?.cancel();
      setState(() {
        _workspace = result;
        _runResult = result.executionResult;
        _submission = null;
        _hasLocalDraft = false;
      });
      await _removeLocalDraft(workspace.id);
    } catch (error) {
      if (mounted) _showMessage(tutorErrorMessage(error));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_codeController.text.trim().isEmpty) {
      _showMessage('Nhập code trước khi nộp.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final submission = await ref
          .read(studentCodePulseRepositoryProvider)
          .submit(
            classroomId: widget.classroom.id,
            assignmentId: widget.assignment.id,
            sourceCode: _codeController.text,
            labId: widget.lab?.id,
            labAssignmentId: widget.labAssignment?.id,
          );
      if (!mounted) return;
      _draftTimer?.cancel();
      final workspace = _workspace;
      setState(() {
        _submission = submission;
        _hasLocalDraft = false;
        if (workspace != null) {
          _workspace = workspace.copyWith(
            sourceCode: _codeController.text,
            updatedAt: submission.submittedAt,
          );
        }
      });
      if (workspace != null) {
        await _removeLocalDraft(workspace.id);
      }
    } catch (error) {
      if (mounted) _showMessage(tutorErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onCodeChanged() {
    if (_loading || _workspace == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistLocalDraft());
    });
  }

  Future<void> _persistLocalDraft() async {
    final workspace = _workspace;
    if (workspace == null) return;
    final sourceCode = _codeController.text;
    if (sourceCode == workspace.sourceCode) {
      await _removeLocalDraft(workspace.id);
      if (mounted && _hasLocalDraft) {
        setState(() => _hasLocalDraft = false);
      }
      return;
    }
    try {
      await _draftStorage.write(workspace.id, _draftForm, {
        'sourceCode': sourceCode,
        'draftAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Không lưu được bản nháp trên thiết bị. Hãy lưu bài lên máy chủ.',
        );
      }
      return;
    }
    if (mounted && !_hasLocalDraft) setState(() => _hasLocalDraft = true);
  }

  Future<Map<String, dynamic>?> _readLocalDraft(String workspaceId) async {
    try {
      return await _draftStorage.read(workspaceId, _draftForm);
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeLocalDraft(String workspaceId) async {
    try {
      await _draftStorage.remove(workspaceId, _draftForm);
    } catch (_) {
      // A device-store issue should not make a server save look unsuccessful.
    }
  }

  String _savedMessage(StudentCodePulseWorkspace workspace) {
    final updatedAt = workspace.updatedAt?.toLocal();
    if (updatedAt == null) return 'Đã lưu bài làm lên máy chủ.';
    final localizations = MaterialLocalizations.of(context);
    return 'Đã lưu lúc ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt))}.';
  }

  Future<void> _revealHint(StudentCodePulseHint hint) async {
    final workspace = _workspace;
    if (workspace == null || !_practiceOpen || _revealingHintId != null) return;
    setState(() => _revealingHintId = hint.id);
    try {
      final updated = await ref
          .read(studentCodePulseRepositoryProvider)
          .revealHint(workspaceId: workspace.id, hintId: hint.id);
      if (!mounted) return;
      setState(() => _workspace = updated);
    } catch (error) {
      if (mounted) _showMessage(tutorErrorMessage(error));
    } finally {
      if (mounted) setState(() => _revealingHintId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignment.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const TutorLoadingView()
          : _loadError != null
          ? TutorErrorView(
              message: tutorErrorMessage(_loadError!),
              onRetry: _loadWorkspace,
            )
          : _workspace == null
          ? TutorErrorView(
              message: 'Không nhận được workspace từ máy chủ.',
              onRetry: _loadWorkspace,
            )
          : _buildWorkspace(context),
      bottomNavigationBar: _loading || _loadError != null || _workspace == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Lưu bài làm',
                      child: SizedBox.square(
                        dimension: 48,
                        child: OutlinedButton(
                          onPressed:
                              _saving ||
                                  _running ||
                                  _submitting ||
                                  !_practiceOpen
                              ? null
                              : _save,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: _saving
                              ? const _ButtonProgress()
                              : const Icon(Icons.save_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _saving || _running || _submitting || !_practiceOpen
                            ? null
                            : _run,
                        icon: _running
                            ? const _ButtonProgress()
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('Chạy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _saving || _running || _submitting || !_practiceOpen
                            ? null
                            : _submit,
                        icon: _submitting
                            ? const _ButtonProgress()
                            : const Icon(Icons.send_outlined),
                        label: const Text('Nộp'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWorkspace(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        if (widget.labAssignment != null && !_practiceOpen) ...[
          _PracticeWindowNotice(
            reason:
                _optionalPracticeReason(_workspace?.practiceWindow) ??
                widget.labAssignment?.accessReason,
          ),
          const SizedBox(height: 12),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.lab == null
                            ? widget.classroom.name
                            : '${widget.classroom.name} · ${widget.lab!.name}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _RuntimeLabel(runtime: widget.assignment.runtime),
                  ],
                ),
                if (widget.assignment.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.assignment.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (widget.assignment.constraints?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ràng buộc',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.assignment.constraints!),
                ],
                if (widget.assignment.inputFormat?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Dữ liệu vào',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.assignment.inputFormat!),
                ],
                if (widget.assignment.outputFormat?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Dữ liệu ra',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.assignment.outputFormat!),
                ],
              ],
            ),
          ),
        ),
        if (widget.assignment.examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ExamplesPanel(examples: widget.assignment.examples),
        ],
        if (_workspace!.hints.isNotEmpty) ...[
          const SizedBox(height: 12),
          _HintsPanel(
            hints: _workspace!.hints,
            enabled: _practiceOpen && _revealingHintId == null,
            revealingHintId: _revealingHintId,
            onReveal: _revealHint,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Bài làm',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _runtimeName(widget.assignment.runtime),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF17212B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _codeController,
            readOnly: _saving || _running || _submitting || !_practiceOpen,
            minLines: 16,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            scrollPadding: const EdgeInsets.all(24),
            style: const TextStyle(
              color: Color(0xFFE5EDF4),
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
            ),
            cursorColor: const Color(0xFF9AB5FF),
            decoration: const InputDecoration(
              hintText: 'Code của bạn…',
              hintStyle: TextStyle(color: Color(0xFF82909C)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        if (_hasLocalDraft) ...[
          const SizedBox(height: 7),
          Text(
            'Bản nháp mới hơn đang được giữ an toàn trên thiết bị.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ] else if (_workspace?.updatedAt != null) ...[
          const SizedBox(height: 7),
          Text(
            _savedMessage(_workspace!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        if (_runResult != null) ...[
          const SizedBox(height: 18),
          _ExecutionPanel(result: _runResult!),
        ],
        if (_submission != null) ...[
          const SizedBox(height: 12),
          _SubmissionPanel(submission: _submission!),
        ],
      ],
    );
  }
}

class _ExecutionPanel extends StatelessWidget {
  const _ExecutionPanel({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final status = result['status'] is String ? result['status'] as String : '';
    final passed = result['passedCount'] is num
        ? (result['passedCount'] as num).toInt()
        : null;
    final total = result['totalCount'] is num
        ? (result['totalCount'] as num).toInt()
        : null;
    final stdout = result['stdout'] is String ? result['stdout'] as String : '';
    final stderr = result['stderr'] is String ? result['stderr'] as String : '';
    final isSuccess =
        status == 'COMPLETED' && (passed == null || passed == total);
    final results = result['results'];
    final cases = results is List
        ? results.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                  color: isSuccess ? const Color(0xFF137547) : colors.error,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Kết quả chạy thử',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (passed != null && total != null)
                  Text('$passed/$total test'),
              ],
            ),
            if (cases.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var index = 0; index < cases.length; index++)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Icon(
                        cases[index]['passed'] == true
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 18,
                        color: cases[index]['passed'] == true
                            ? const Color(0xFF137547)
                            : colors.error,
                      ),
                      const SizedBox(width: 8),
                      Text('Test ${index + 1}'),
                      const Spacer(),
                      Text(
                        cases[index]['status'] is String
                            ? cases[index]['status'] as String
                            : 'Chưa rõ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
            if (stdout.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _OutputLabel(label: 'Đầu ra'),
              const SizedBox(height: 5),
              _OutputText(text: stdout),
            ],
            if (stderr.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _OutputLabel(label: 'Thông báo lỗi'),
              const SizedBox(height: 5),
              _OutputText(text: stderr, isError: true),
            ],
            if (stdout.isEmpty && stderr.isEmpty && cases.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _executionLabel(status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionPanel extends StatelessWidget {
  const _SubmissionPanel({required this.submission});

  final StudentCodePulseSubmission submission;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5F5EC),
          foregroundColor: const Color(0xFF137547),
          child: const Icon(Icons.task_alt_rounded),
        ),
        title: const Text('Đã nộp và chấm xong'),
        subtitle: Text(
          '${submission.passedCount}/${submission.totalCount} test · Điểm ${submission.score}',
        ),
        trailing: Icon(Icons.check_circle, color: colors.primary),
      ),
    );
  }
}

class _ExamplesPanel extends StatelessWidget {
  const _ExamplesPanel({required this.examples});

  final List<StudentCodePulseExample> examples;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ví dụ công khai',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (var index = 0; index < examples.length; index++) ...[
            const SizedBox(height: 12),
            Text(
              'Ví dụ ${index + 1}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            _OutputLabelledBlock(
              label: 'Đầu vào',
              value: examples[index].input,
            ),
            const SizedBox(height: 6),
            _OutputLabelledBlock(
              label: 'Đầu ra',
              value: examples[index].output,
            ),
          ],
        ],
      ),
    ),
  );
}

class _OutputLabelledBlock extends StatelessWidget {
  const _OutputLabelledBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 3),
      _OutputText(text: value.isEmpty ? '—' : value),
    ],
  );
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel({
    required this.hints,
    required this.enabled,
    required this.revealingHintId,
    required this.onReveal,
  });

  final List<StudentCodePulseHint> hints;
  final bool enabled;
  final String? revealingHintId;
  final Future<void> Function(StudentCodePulseHint) onReveal;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (var index = 0; index < hints.length; index++) ...[
            if (index > 0) const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hints[index].title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hints[index].revealed &&
                          hints[index].content?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(hints[index].content!),
                      ],
                    ],
                  ),
                ),
                if (!hints[index].revealed)
                  TextButton(
                    onPressed: !enabled ? null : () => onReveal(hints[index]),
                    child: revealingHintId == hints[index].id
                        ? const _ButtonProgress()
                        : const Text('Mở'),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.check_circle_outline, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _OutputLabel extends StatelessWidget {
  const _OutputLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _OutputText extends StatelessWidget {
  const _OutputText({required this.text, this.isError = false});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFF0EF) : const Color(0xFFF1F4F7),
      borderRadius: BorderRadius.circular(10),
    ),
    child: SelectableText(
      text,
      style: TextStyle(
        color: isError ? const Color(0xFF8D2620) : const Color(0xFF29343B),
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.4,
      ),
    ),
  );
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

String _runtimeName(String runtime) => switch (runtime.toUpperCase()) {
  'CPP' => 'C++',
  'PYTHON' => 'Python',
  _ => runtime,
};

String _executionLabel(String status) => switch (status) {
  'COMPLETED' => 'Chương trình chạy hoàn tất.',
  'FAILED' => 'Một số test chưa đạt.',
  'RUNTIME_ERROR' => 'Chương trình gặp lỗi khi chạy.',
  _ => 'Backend chưa trả trạng thái chạy.',
};
