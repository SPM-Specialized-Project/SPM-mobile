import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/tutor_course.dart';
import 'tutor_ui.dart';

const courseContentTypes = {
  'introduction': 'Giới thiệu',
  'material': 'Tài liệu',
  'movie': 'Video bài giảng',
  'note': 'Bài tập',
  'submission': 'Nộp bài',
  'reference': 'Đường dẫn',
  'bookReference': 'Sách tham khảo',
};

class TutorCourseContent extends StatelessWidget {
  const TutorCourseContent({
    required this.course,
    required this.sections,
    required this.editable,
    required this.onChanged,
    super.key,
  });
  final TutorCourse course;
  final List<TutorCourseSection> sections;
  final bool editable;
  final ValueChanged<List<TutorCourseSection>> onChanged;

  Future<void> _edit(BuildContext context, [int? index]) async {
    final item = await showModalBottomSheet<TutorCourseSection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _SectionEditor(section: index == null ? null : sections[index]),
    );
    if (item == null) return;
    final next = List.of(sections);
    if (index == null) {
      next.add(item);
    } else {
      next[index] = item;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(course.code, style: Theme.of(context).textTheme.labelLarge),
      Text('Giảng viên: ${course.instructor}'),
      const SizedBox(height: 16),
      TutorPageHeading(
        title: 'Nội dung môn học',
        subtitle: '${sections.length} danh mục',
      ),
      if (editable)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm danh mục'),
          ),
        ),
      if (sections.isEmpty)
        const TutorEmptyView(
          icon: Icons.menu_book_outlined,
          title: 'Chưa có nội dung',
          message: 'Bật chỉnh sửa để thêm nội dung môn học.',
        ),
      for (var i = 0; i < sections.length; i++)
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sections[i].title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (editable) ...[
                      IconButton(
                        tooltip: 'Sửa ${sections[i].title}',
                        onPressed: () => _edit(context, i),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Xóa ${sections[i].title}',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xóa danh mục?'),
                              content: Text(sections[i].title),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            onChanged(List.of(sections)..removeAt(i));
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
                Text(
                  courseContentTypes[sections[i].type] ?? 'Nội dung khác',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Divider(),
                _SectionBody(section: sections[i]),
                if (editable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Di chuyển lên',
                        onPressed: i == 0
                            ? null
                            : () {
                                final next = List.of(sections);
                                final item = next.removeAt(i);
                                next.insert(i - 1, item);
                                onChanged(next);
                              },
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Di chuyển xuống',
                        onPressed: i == sections.length - 1
                            ? null
                            : () {
                                final next = List.of(sections);
                                final item = next.removeAt(i);
                                next.insert(i + 1, item);
                                onChanged(next);
                              },
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});
  final TutorCourseSection section;
  @override
  Widget build(BuildContext context) {
    final data = section.data;
    if (section.type == 'introduction') {
      return SelectableText(data['text'] as String? ?? '');
    }
    if (section.type == 'submission') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.description.isNotEmpty) Text(section.description),
          Text(
            'Hạn nộp: ${data['dueDate'] == null || data['dueDate'] == '' ? 'Chưa đặt' : data['dueDate']}',
          ),
          Text(
            'Tối đa ${data['maxFiles'] ?? 1} file · ${(data['allowedTypes'] as List? ?? []).join(', ')}',
          ),
        ],
      );
    }
    if (section.type == 'bookReference') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final book in data['books'] as List? ?? [])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SelectableText(
                '${book['name'] ?? book['title'] ?? ''}\n${book['author'] ?? ''}\n${book['url'] ?? book['source'] ?? ''}',
              ),
            ),
        ],
      );
    }
    final key = switch (section.type) {
      'material' => 'document',
      'movie' => 'video',
      'note' => 'assignment',
      _ => 'link',
    };
    final nested = data[key] as Map? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nested['title'] != null)
          Text(
            nested['title'].toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (nested['description'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(nested['description'].toString()),
          ),
        if (nested['source'] != null || nested['url'] != null)
          SelectableText((nested['url'] ?? nested['source']).toString()),
        if (nested['dueDate'] != null && nested['dueDate'] != '')
          Text('Hạn: ${nested['dueDate']}'),
        if (nested.isEmpty) const Text('Chưa có nội dung chi tiết.'),
      ],
    );
  }
}

class _SectionEditor extends StatefulWidget {
  const _SectionEditor({this.section});
  final TutorCourseSection? section;
  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late String _type = widget.section?.type ?? 'introduction';
  late Map<String, dynamic> _data =
      jsonDecode(jsonEncode(widget.section?.data ?? {}))
          as Map<String, dynamic>;
  late final _title = TextEditingController(text: widget.section?.title ?? '');
  late final _description = TextEditingController(
    text: widget.section?.description ?? '',
  );
  TextEditingController _controller(String key, [Object? value]) =>
      _fields.putIfAbsent(
        key,
        () => TextEditingController(text: value?.toString() ?? ''),
      );
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label,
    Object? value, {
    int lines = 1,
    bool required = false,
    bool number = false,
    bool date = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controller(key, value),
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: date ? '2026-10-15T23:59' : null,
      ),
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Vui lòng nhập $label.';
        }
        if (number && (int.tryParse(value ?? '') ?? 0) < 1) {
          return 'Nhập số nguyên dương.';
        }
        if (date &&
            value != null &&
            value.isNotEmpty &&
            DateTime.tryParse(value) == null) {
          return 'Nhập ngày giờ theo định dạng năm-tháng-ngàyTgiờ:phút.';
        }
        if (key.endsWith('.url') && value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value.trim());
          if (uri == null ||
              !['http', 'https'].contains(uri.scheme) ||
              uri.host.isEmpty) {
            return 'Nhập URL http hoặc https hợp lệ.';
          }
        }
        return null;
      },
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final next = Map<String, dynamic>.from(_data);
    for (final entry in _fields.entries) {
      final parts = entry.key.split('.');
      final text = entry.value.text.trim();
      Object value = text;
      if (['maxFiles', 'maxFileSize'].contains(entry.key)) {
        value = int.parse(text);
      }
      if (entry.key == 'allowedTypes') {
        value = text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (parts.length == 1) {
        next[parts.first] = value;
      } else {
        final nested = Map<String, dynamic>.from(
          next[parts.first] as Map? ?? {},
        );
        nested[parts.last] = value;
        nested.putIfAbsent(
          'id',
          () =>
              '${widget.section?.id ?? DateTime.now().microsecondsSinceEpoch}-${parts.first}',
        );
        next[parts.first] = nested;
      }
    }
    Navigator.pop(
      context,
      TutorCourseSection(
        id:
            widget.section?.id ??
            'content-${DateTime.now().microsecondsSinceEpoch}',
        type: _type,
        title: _title.text.trim(),
        description: _description.text.trim(),
        data: next,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nestedKey = switch (_type) {
      'material' => 'document',
      'movie' => 'video',
      'note' => 'assignment',
      _ => 'link',
    };
    final nested = _data[nestedKey] as Map? ?? {};
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.section == null ? 'Thêm danh mục' : 'Sửa danh mục',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên danh mục.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Loại nội dung'),
                items: courseContentTypes.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == _type) return;
                  setState(() {
                    _type = value;
                    _data = {};
                    for (final controller in _fields.values) {
                      controller.dispose();
                    }
                    _fields.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_type == 'introduction')
                _field('text', 'Nội dung giới thiệu', _data['text'], lines: 6),
              if ([
                'material',
                'movie',
                'note',
                'reference',
              ].contains(_type)) ...[
                _field(
                  '$nestedKey.title',
                  'Tiêu đề nội dung',
                  nested['title'],
                  required: true,
                ),
                if (_type != 'reference')
                  _field(
                    '$nestedKey.description',
                    'Mô tả',
                    nested['description'],
                    lines: 4,
                  ),
                _field(
                  '$nestedKey.${_type == 'material' || _type == 'note' ? 'source' : 'url'}',
                  _type == 'movie' ? 'URL video' : 'Đường dẫn tài liệu',
                  nested['source'] ?? nested['url'],
                ),
                if (_type == 'note')
                  _field(
                    '$nestedKey.dueDate',
                    'Hạn hoàn thành',
                    nested['dueDate'],
                    date: true,
                  ),
              ],
              if (_type == 'submission') ...[
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả bài nộp'),
                ),
                const SizedBox(height: 12),
                _field('dueDate', 'Hạn nộp', _data['dueDate'], date: true),
                _field(
                  'allowedTypes',
                  'Đuôi file cho phép (cách nhau bằng dấu phẩy)',
                  (_data['allowedTypes'] as List? ?? []).join(', '),
                ),
                _field(
                  'maxFiles',
                  'Số file tối đa',
                  _data['maxFiles'] ?? 1,
                  number: true,
                ),
                _field(
                  'maxFileSize',
                  'Dung lượng file tối đa',
                  _data['maxFileSize'] ?? 10,
                  number: true,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _data['maxFileSizeUnit'] as String? ?? 'MB',
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị dung lượng',
                  ),
                  items: ['KB', 'MB', 'GB']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _data['maxFileSizeUnit'] = value,
                ),
              ],
              if (_type == 'bookReference') ...[
                for (var i = 0; i < (_data['books'] as List? ?? []).length; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue:
                                (_data['books'] as List)[i]['name']
                                    as String? ??
                                '',
                            decoration: const InputDecoration(
                              labelText: 'Tên sách',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nhập tên sách.'
                                : null,
                            onChanged: (value) =>
                                (_data['books'] as List)[i]['name'] = value,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue:
                                (_data['books'] as List)[i]['author']
                                    as String? ??
                                '',
                            decoration: const InputDecoration(
                              labelText: 'Tác giả',
                            ),
                            onChanged: (value) =>
                                (_data['books'] as List)[i]['author'] = value,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue:
                                (_data['books'] as List)[i]['url'] as String? ??
                                '',
                            decoration: const InputDecoration(
                              labelText: 'Đường dẫn sách',
                            ),
                            onChanged: (value) =>
                                (_data['books'] as List)[i]['url'] = value,
                          ),
                        ],
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    (_data.putIfAbsent('books', () => <dynamic>[]) as List).add(
                      <String, dynamic>{'name': '', 'author': '', 'url': ''},
                    );
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sách'),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                child: const Text('Áp dụng thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
