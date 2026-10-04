import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tutor_dsa_providers.dart';
import 'tutor_course_forms.dart';
import 'tutor_ui.dart';

class TutorDsaLabEditor extends ConsumerStatefulWidget {
  const TutorDsaLabEditor({
    required this.classroomId,
    required this.versions,
    super.key,
  });
  final String classroomId;
  final List<Map<String, dynamic>> versions;
  @override
  ConsumerState<TutorDsaLabEditor> createState() => _LabEditorState();
}

class _LabEditorState extends ConsumerState<TutorDsaLabEditor> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _description = TextEditingController();
  final _selected = <Map<String, dynamic>>[];
  DateTime _start = DateTime.now(),
      _end = DateTime.now().add(const Duration(hours: 5));
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
    title: const Text('Tạo LAB mới'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên LAB'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập tên LAB.' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              CourseDateTimeField(
                label: 'Bắt đầu LAB',
                value: _start,
                onChanged: (value) => setState(() {
                  final previous = _start;
                  _start = value;
                  for (final item in _selected) {
                    if (item['openAt'] == previous) item['openAt'] = value;
                  }
                }),
              ),
              CourseDateTimeField(
                label: 'Kết thúc LAB',
                value: _end,
                onChanged: (value) => setState(() {
                  final previous = _end;
                  _end = value;
                  for (final item in _selected) {
                    if (item['closeAt'] == previous) item['closeAt'] = value;
                  }
                }),
              ),
              const Text(
                'Bài đã publish',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              for (final version in widget.versions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${version['title']} · v${version['version']}'),
                  value: _selected.any(
                    (s) => s['assignmentVersionId'] == version['id'],
                  ),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            _selected.add({
                              'assignmentVersionId': version['id'],
                              'title': version['title'],
                              'mandatory': true,
                              'openAt': _start,
                              'closeAt': _end,
                            });
                          } else {
                            _selected.removeWhere(
                              (s) => s['assignmentVersionId'] == version['id'],
                            );
                          }
                        }),
                ),
              for (var i = 0; i < _selected.length; i++)
                Card(
                  key: ValueKey(_selected[i]['assignmentVersionId']),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${i + 1}. ${_selected[i]['title']}'),
                            ),
                            IconButton(
                              tooltip: 'Lên trước',
                              onPressed: i == 0 || _saving
                                  ? null
                                  : () => setState(() {
                                      final item = _selected.removeAt(i);
                                      _selected.insert(i - 1, item);
                                    }),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Xuống sau',
                              onPressed: i == _selected.length - 1 || _saving
                                  ? null
                                  : () => setState(() {
                                      final item = _selected.removeAt(i);
                                      _selected.insert(i + 1, item);
                                    }),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Bắt buộc'),
                          value: _selected[i]['mandatory'] as bool,
                          onChanged: _saving
                              ? null
                              : (v) => setState(
                                  () => _selected[i]['mandatory'] = v,
                                ),
                        ),
                        CourseDateTimeField(
                          label: 'Mở practice',
                          value: _selected[i]['openAt'] as DateTime,
                          onChanged: (v) =>
                              setState(() => _selected[i]['openAt'] = v),
                        ),
                        CourseDateTimeField(
                          label: 'Đóng practice',
                          value: _selected[i]['closeAt'] as DateTime,
                          onChanged: (v) =>
                              setState(() => _selected[i]['closeAt'] = v),
                        ),
                      ],
                    ),
                  ),
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
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _saving || _selected.isEmpty
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) return;
                if (!_end.isAfter(_start) ||
                    _selected.any(
                      (s) => !(s['closeAt'] as DateTime).isAfter(
                        s['openAt'] as DateTime,
                      ),
                    )) {
                  setState(() => _error = 'Giờ kết thúc phải sau giờ bắt đầu.');
                  return;
                }
                setState(() {
                  _saving = true;
                  _error = null;
                });
                try {
                  await ref.read(tutorDsaRepositoryProvider).createLab(
                    widget.classroomId,
                    {
                      'name': _name.text.trim(),
                      'description': _description.text.trim(),
                      'startAt': _start.toUtc().toIso8601String(),
                      'endAt': _end.toUtc().toIso8601String(),
                      'assignments': _selected
                          .map(
                            (s) => {
                              'assignmentVersionId': s['assignmentVersionId'],
                              'mandatory': s['mandatory'],
                              'openAt': (s['openAt'] as DateTime)
                                  .toUtc()
                                  .toIso8601String(),
                              'closeAt': (s['closeAt'] as DateTime)
                                  .toUtc()
                                  .toIso8601String(),
                            },
                          )
                          .toList(),
                    },
                  );
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
        child: Text(
          _saving ? 'Đang tạo...' : 'Tạo LAB (${_selected.length} bài)',
        ),
      ),
    ],
  );
}

class TutorPracticeWindowEditor extends ConsumerStatefulWidget {
  const TutorPracticeWindowEditor({
    required this.classroomId,
    required this.labId,
    required this.assignment,
    super.key,
  });
  final String classroomId, labId;
  final Map<String, dynamic> assignment;
  @override
  ConsumerState<TutorPracticeWindowEditor> createState() =>
      _PracticeWindowEditorState();
}

class _PracticeWindowEditorState
    extends ConsumerState<TutorPracticeWindowEditor> {
  late DateTime _open = DateTime.parse(
    widget.assignment['openAt'] as String,
  ).toLocal();
  late DateTime _close = DateTime.parse(
    widget.assignment['closeAt'] as String,
  ).toLocal();
  late String _status =
      widget.assignment['practiceWindowStatus'] as String? ?? 'OPEN';
  bool _saving = false;
  String? _error;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Khung giờ practice'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.assignment['title'] as String),
          const SizedBox(height: 16),
          CourseDateTimeField(
            label: 'Mở practice',
            value: _open,
            onChanged: (v) => setState(() => _open = v),
          ),
          CourseDateTimeField(
            label: 'Đóng practice',
            value: _close,
            onChanged: (v) => setState(() => _close = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: const [
              DropdownMenuItem(value: 'OPEN', child: Text('Mở theo khung giờ')),
              DropdownMenuItem(value: 'CLOSED', child: Text('Đóng thủ công')),
            ],
            onChanged: _saving ? null : (value) => _status = value!,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
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
                if (!_close.isAfter(_open)) {
                  setState(() => _error = 'Giờ đóng phải sau giờ mở.');
                  return;
                }
                setState(() {
                  _saving = true;
                  _error = null;
                });
                try {
                  await ref.read(tutorDsaRepositoryProvider).updatePractice(
                    widget.classroomId,
                    widget.labId,
                    widget.assignment,
                    {
                      'openAt': _open.toUtc().toIso8601String(),
                      'closeAt': _close.toUtc().toIso8601String(),
                      'status': _status,
                    },
                  );
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
        child: Text(_saving ? 'Đang lưu...' : 'Lưu thời gian'),
      ),
    ],
  );
}
