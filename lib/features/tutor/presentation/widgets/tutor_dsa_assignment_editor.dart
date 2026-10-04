import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tutor_dsa_providers.dart';
import 'tutor_course_forms.dart';
import 'tutor_ui.dart';

class TutorDsaAssignmentEditor extends ConsumerStatefulWidget {
  const TutorDsaAssignmentEditor({
    required this.classroomId,
    required this.editable,
    this.assignment,
    super.key,
  });
  final String classroomId;
  final bool editable;
  final Map<String, dynamic>? assignment;
  @override
  ConsumerState<TutorDsaAssignmentEditor> createState() =>
      _AssignmentEditorState();
}

class _AssignmentEditorState extends ConsumerState<TutorDsaAssignmentEditor> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _testFields = <String, TextEditingController>{};
  late Map<String, dynamic> _assignment = Map.of(widget.assignment ?? {});
  late List<Map<String, dynamic>> _tests =
      (jsonDecode(jsonEncode(widget.assignment?['testCases'] ?? [])) as List)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();
  late String _runtime =
      (widget.assignment?['runtime'] as String?)?.isNotEmpty == true
      ? widget.assignment!['runtime'] as String
      : 'PYTHON';
  bool _dirty = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [..._fields.values, ..._testFields.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _fieldController(String key) => _fields.putIfAbsent(
    key,
    () => TextEditingController(
      text:
          _assignment[key]?.toString() ??
          (key == 'cpuTimeLimitMs'
              ? '1000'
              : key == 'memoryLimitMb'
              ? '128'
              : ''),
    ),
  );
  Widget _field(
    String key,
    String label, {
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fieldController(key),
      readOnly: !widget.editable || _busy,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 5,
      keyboardType: number ? TextInputType.number : TextInputType.multiline,
      style: key == 'referenceSolution'
          ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
          : null,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
      ),
      onChanged: (_) => setState(() => _dirty = true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập $label.';
        }
        if (number && (int.tryParse(value) ?? 0) < 1) {
          return 'Nhập số nguyên dương.';
        }
        return null;
      },
    ),
  );

  Future<void> _perform(String action) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(tutorDsaRepositoryProvider);
      if (_dirty || _assignment['id'] == null) {
        _assignment = await repository.saveAssignment(
          widget.classroomId,
          _assignment['id'] as String?,
          {
            for (final entry in _fields.entries)
              entry.key: ['cpuTimeLimitMs', 'memoryLimitMb'].contains(entry.key)
                  ? int.parse(entry.value.text.trim())
                  : entry.value.text.trim(),
            'runtime': _runtime,
            'testCases': _tests
                .map(
                  (t) => {
                    'id': t['id'],
                    'input': t['input'] ?? '',
                    'expectedOutput': t['expectedOutput'] ?? '',
                    'hidden': t['hidden'] == true,
                  },
                )
                .toList(),
          },
        );
        _dirty = false;
      }
      if (action != 'save') {
        _assignment = await repository.assignmentAction(
          widget.classroomId,
          _assignment['id'] as String,
          action,
        );
      }
      _tests = (_assignment['testCases'] as List)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();
      ref.invalidate(tutorDsaWorkspaceProvider(widget.classroomId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'verify'
                  ? 'Đã verify lời giải mẫu'
                  : action == 'publish'
                  ? 'Đã publish bài tập'
                  : 'Đã lưu bài tập',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _error = tutorErrorMessage(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_busy,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || _busy) return;
      if (await confirmCourseAction(
        context,
        'Bỏ thay đổi chưa lưu?',
        'Nội dung bài tập chưa được lưu.',
      )) {
        if (!mounted) return;
        setState(() => _dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignment == null ? 'Bài tập mới' : 'Chi tiết bài tập',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${_assignment['status'] ?? 'DRAFT'} · ${_assignment['verificationStatus'] ?? 'UNVERIFIED'}',
            ),
            const SizedBox(height: 16),
            _field('title', 'Tiêu đề'),
            _field('description', 'Mô tả', lines: 4),
            _field('constraints', 'Ràng buộc', lines: 2),
            _field(
              'inputFormat',
              'Định dạng đầu vào (hoặc No input)',
              lines: 2,
            ),
            _field('outputFormat', 'Định dạng đầu ra', lines: 2),
            _field('cpuTimeLimitMs', 'Giới hạn CPU (ms)', number: true),
            _field('memoryLimitMb', 'Giới hạn bộ nhớ (MB)', number: true),
            DropdownButtonFormField<String>(
              initialValue: _runtime,
              decoration: const InputDecoration(labelText: 'Runtime'),
              items: ['PYTHON', 'CPP']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s == 'CPP' ? 'C++' : 'Python'),
                    ),
                  )
                  .toList(),
              onChanged: !widget.editable || _busy
                  ? null
                  : (value) => setState(() {
                      _runtime = value!;
                      _dirty = true;
                    }),
            ),
            const SizedBox(height: 12),
            _field('referenceSolution', 'Lời giải mẫu', lines: 8),
            Text('Test cases', style: Theme.of(context).textTheme.titleLarge),
            for (var i = 0; i < _tests.length; i++) _testCard(i),
            if (widget.editable)
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _tests.add({
                          'id': 'test-${DateTime.now().microsecondsSinceEpoch}',
                          'input': '',
                          'expectedOutput': '',
                          'hidden': false,
                        });
                        _dirty = true;
                      }),
                icon: const Icon(Icons.add),
                label: const Text('Thêm test case'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (widget.editable) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () => _perform('save'),
                child: Text(_busy ? 'Đang xử lý...' : 'Lưu bài tập'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _perform('verify'),
                child: const Text('Verify lời giải mẫu'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (await confirmCourseAction(
                          context,
                          'Publish bài tập?',
                          'Sinh viên có quyền truy cập sẽ xem được phiên bản đã publish.',
                        )) {
                          await _perform('publish');
                        }
                      },
                child: const Text('Publish'),
              ),
              if (_assignment['id'] != null && _assignment['status'] == 'DRAFT')
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (!await confirmCourseAction(
                            context,
                            'Xóa bản nháp?',
                            'Xóa ${_assignment['title']}',
                          )) {
                            return;
                          }
                          setState(() => _busy = true);
                          try {
                            await ref
                                .read(tutorDsaRepositoryProvider)
                                .deleteAssignment(
                                  widget.classroomId,
                                  _assignment['id'] as String,
                                );
                            if (!mounted) return;
                            setState(() {
                              _dirty = false;
                              _busy = false;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) Navigator.pop(context);
                            });
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _busy = false;
                                _error = tutorErrorMessage(e);
                              });
                            }
                          }
                        },
                  child: const Text('Xóa bản nháp'),
                ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _testCard(int index) {
    final test = _tests[index];
    return Card(
      key: ValueKey(test['id']),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Test ${index + 1}${test['verified'] == true && !_dirty ? ' · Verified' : ''}',
                  ),
                ),
                if (widget.editable)
                  IconButton(
                    tooltip: 'Xóa test case',
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _tests.removeAt(index);
                            _dirty = true;
                          }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            for (final entry in {
              'input': 'Đầu vào',
              'expectedOutput': 'Đầu ra kỳ vọng',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _testFields.putIfAbsent(
                    '${test['id']}.${entry.key}',
                    () => TextEditingController(
                      text: test[entry.key] as String? ?? '',
                    ),
                  ),
                  minLines: 2,
                  maxLines: 6,
                  readOnly: !widget.editable || _busy,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(labelText: entry.value),
                  onChanged: (value) {
                    test[entry.key] = value;
                    setState(() => _dirty = true);
                  },
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Test ẩn'),
              value: test['hidden'] == true,
              onChanged: !widget.editable || _busy
                  ? null
                  : (v) => setState(() {
                      test['hidden'] = v;
                      _dirty = true;
                    }),
            ),
          ],
        ),
      ),
    );
  }
}
