import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tutor_dsa_providers.dart';
import '../../data/tutor_dsa_repository.dart';
import 'tutor_ui.dart';
import 'tutor_course_forms.dart';
import 'tutor_dsa_assignment_editor.dart';
import 'tutor_dsa_lab_editor.dart';

class TutorDsaTab extends ConsumerStatefulWidget {
  const TutorDsaTab({required this.editable, super.key});
  final bool editable;
  @override
  ConsumerState<TutorDsaTab> createState() => _TutorDsaTabState();
}

class _TutorDsaTabState extends ConsumerState<TutorDsaTab>
    with AutomaticKeepAliveClientMixin {
  String _term = 'current';
  String? _classroomId;
  bool _busy = false;
  @override
  bool get wantKeepAlive => true;

  Future<void> _mutate(String id, Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
      }
    } finally {
      ref.invalidate(tutorDsaWorkspaceProvider(id));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ref
        .watch(tutorDsaCatalogProvider)
        .when(
          loading: () => const TutorLoadingView(),
          error: (error, _) => TutorErrorView(
            message: tutorErrorMessage(error),
            onRetry: () => ref.invalidate(tutorDsaCatalogProvider),
          ),
          data: (catalog) {
            final now = DateTime.now();
            final currentTermIds = catalog.terms
                .where(
                  (t) =>
                      t.status == 'ACTIVE' &&
                      !now.isBefore(t.startDate) &&
                      now.isBefore(t.endDate),
                )
                .map((t) => t.id)
                .toSet();
            final classrooms = catalog.classrooms
                .where(
                  (c) =>
                      _term == 'all' ||
                      (_term == 'current'
                          ? currentTermIds.contains(c.termId)
                          : c.termId == _term),
                )
                .toList();
            final selectedId = classrooms.any((c) => c.id == _classroomId)
                ? _classroomId
                : classrooms.firstOrNull?.id;
            final selected = classrooms
                .where((c) => c.id == selectedId)
                .firstOrNull;
            return RefreshIndicator(
              onRefresh: () async {
                await ref
                    .refresh(tutorDsaCatalogProvider.future)
                    .then<void>((_) {});
                if (selectedId != null) {
                  ref.invalidate(tutorDsaWorkspaceProvider(selectedId));
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const TutorPageHeading(
                    title: 'Terms and classrooms',
                    subtitle: 'Học kỳ, lớp DSA, bài tập và buổi LAB.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_term),
                    initialValue: _term,
                    decoration: const InputDecoration(labelText: 'Học kỳ'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: 'current',
                        child: Text('Học kỳ hiện tại'),
                      ),
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả học kỳ'),
                      ),
                      for (final term in catalog.terms)
                        DropdownMenuItem(
                          value: term.id,
                          child: Text('${term.name} (${term.status})'),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _term = value!;
                      _classroomId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (classrooms.isEmpty)
                    const TutorEmptyView(
                      icon: Icons.school_outlined,
                      title: 'Chưa có classroom',
                      message: 'Chọn học kỳ khác để xem lớp được phân công.',
                    ),
                  if (selected != null) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(selected.id),
                      initialValue: selected.id,
                      decoration: const InputDecoration(labelText: 'Classroom'),
                      isExpanded: true,
                      items: [
                        for (final c in classrooms)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (value) =>
                          setState(() => _classroomId = value),
                    ),
                    Card(
                      elevation: 0,
                      child: ListTile(
                        title: Text(selected.name),
                        subtitle: Text(
                          '${selected.termName ?? selected.termId} · ${selected.status}\n${selected.description}',
                        ),
                        trailing: widget.editable
                            ? IconButton(
                                tooltip: 'Sửa classroom',
                                onPressed: () async {
                                  final changed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) =>
                                        _ClassroomEditor(classroom: selected),
                                  );
                                  if (changed == true) {
                                    ref.invalidate(tutorDsaCatalogProvider);
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                              )
                            : null,
                      ),
                    ),
                    ref
                        .watch(tutorDsaWorkspaceProvider(selected.id))
                        .when(
                          loading: () => const SizedBox(
                            height: 180,
                            child: TutorLoadingView(),
                          ),
                          error: (error, _) => TutorErrorView(
                            message: tutorErrorMessage(error),
                            onRetry: () => ref.invalidate(
                              tutorDsaWorkspaceProvider(selected.id),
                            ),
                          ),
                          data: (workspace) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                'Soạn bài tập',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (widget.editable)
                                OutlinedButton.icon(
                                  onPressed: () => _openAssignment(selected.id),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Bài tập mới'),
                                ),
                              if (workspace.assignments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Chưa có bài tập trong classroom này.',
                                  ),
                                ),
                              for (final assignment in workspace.assignments)
                                Card(
                                  elevation: 0,
                                  child: ListTile(
                                    title: Text(assignment['title'] as String),
                                    subtitle: Text(
                                      '${assignment['status']} · ${assignment['verificationStatus']}',
                                    ),
                                    trailing: Icon(
                                      widget.editable
                                          ? Icons.edit_outlined
                                          : Icons.chevron_right,
                                    ),
                                    onTap: () => _openAssignment(
                                      selected.id,
                                      assignment,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                'Buổi LAB nhiều bài',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Mỗi bài giữ phiên bản, thứ tự và khung giờ practice riêng.',
                                ),
                              ),
                              if (widget.editable)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final saved = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => TutorDsaLabEditor(
                                        classroomId: selected.id,
                                        versions: workspace.versions,
                                      ),
                                    );
                                    if (saved == true) {
                                      ref.invalidate(
                                        tutorDsaWorkspaceProvider(selected.id),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tạo LAB mới'),
                                ),
                              if (workspace.labs.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Chưa có buổi LAB.'),
                                ),
                              for (final lab in workspace.labs)
                                _labCard(selected.id, lab),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        );
  }

  Future<void> _openAssignment(
    String classroomId, [
    Map<String, dynamic>? assignment,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TutorDsaAssignmentEditor(
          classroomId: classroomId,
          assignment: assignment,
          editable: widget.editable,
        ),
      ),
    );
    ref.invalidate(tutorDsaWorkspaceProvider(classroomId));
  }

  Widget _labCard(String classroomId, Map<String, dynamic> lab) {
    final status = lab['status'] as String;
    final transitions = switch (status) {
      'SCHEDULED' => ['LIVE', 'CANCELLED'],
      'LIVE' => ['PAUSED', 'ENDED', 'CANCELLED'],
      'PAUSED' => ['LIVE', 'ENDED'],
      _ => <String>[],
    };
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lab['name'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$status · ${courseDateLabel(lab['startAt'])} – ${courseDateLabel(lab['endAt'])}',
            ),
            if ((lab['description'] as String? ?? '').isNotEmpty)
              Text(lab['description'] as String),
            for (final rawAssignment in lab['assignments'] as List)
              Builder(
                builder: (context) {
                  final assignment = Map<String, dynamic>.from(
                    rawAssignment as Map,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        Text(
                          '${assignment['order']}. ${assignment['title']} · v${assignment['version']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          assignment['mandatory'] == true
                              ? 'Bắt buộc'
                              : 'Tùy chọn',
                        ),
                        Text(
                          'Practice: ${courseDateLabel(assignment['openAt'])} – ${courseDateLabel(assignment['closeAt'])}',
                        ),
                        Text(
                          assignment['practiceWindowStatus'] == 'CLOSED'
                              ? 'Đã đóng thủ công'
                              : assignment['practiceAccess'] == 'OPEN'
                              ? 'Đang mở'
                              : 'Chưa mở hoặc đã hết hạn',
                        ),
                        if (widget.editable)
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final saved = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => TutorPracticeWindowEditor(
                                        classroomId: classroomId,
                                        labId: lab['id'] as String,
                                        assignment: assignment,
                                      ),
                                    );
                                    if (saved == true) {
                                      ref.invalidate(
                                        tutorDsaWorkspaceProvider(classroomId),
                                      );
                                    }
                                  },
                            child: const Text('Chỉnh khung giờ practice'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            if (widget.editable && transitions.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final next in transitions)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await confirmCourseAction(
                                context,
                                'Đổi trạng thái LAB?',
                                '${lab['name']}: $status → $next',
                              )) {
                                await _mutate(
                                  classroomId,
                                  () => ref
                                      .read(tutorDsaRepositoryProvider)
                                      .changeLabStatus(classroomId, lab, next),
                                );
                              }
                            },
                      child: Text(switch (next) {
                        'LIVE' => 'Bắt đầu / tiếp tục',
                        'PAUSED' => 'Tạm dừng',
                        'ENDED' => 'Kết thúc LAB',
                        _ => 'Hủy LAB',
                      }),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ClassroomEditor extends ConsumerStatefulWidget {
  const _ClassroomEditor({required this.classroom});
  final CodePulseClassroom classroom;
  @override
  ConsumerState<_ClassroomEditor> createState() => _ClassroomEditorState();
}

class _ClassroomEditorState extends ConsumerState<_ClassroomEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.classroom.name);
  late final _description = TextEditingController(
    text: widget.classroom.description,
  );
  late String _status = widget.classroom.status;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Sửa classroom'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên lớp'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tên lớp.' : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: [
                'DRAFT',
                'ACTIVE',
                'ARCHIVED',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => _status = s!,
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _saving
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() {
                  _saving = true;
                  _error = null;
                });
                try {
                  await ref
                      .read(tutorDsaRepositoryProvider)
                      .updateClassroom(widget.classroom.id, {
                        'name': _name.text.trim(),
                        'description': _description.text.trim(),
                        'status': _status,
                      });
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _saving = false;
                      _error = tutorErrorMessage(e);
                    });
                  }
                }
              },
        child: Text(_saving ? 'Đang lưu...' : 'Lưu classroom'),
      ),
    ],
  );
}
