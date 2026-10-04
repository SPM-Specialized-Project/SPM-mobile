import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/draft_storage.dart';
import '../data/tssa_repository.dart';

class TssaField {
  const TssaField(
    this.key,
    this.label, {
    this.kind = 'text',
    this.required = false,
    this.requiredWhenKey,
    this.requiredWhenValue,
    this.options = const {},
    this.hint,
    this.value,
  });
  final String key, label, kind;
  final bool required;
  final String? requiredWhenKey;
  final dynamic requiredWhenValue;
  final Map<String, String> options;
  final String? hint;
  final dynamic value;
}

class TssaFormScreen extends ConsumerStatefulWidget {
  const TssaFormScreen({
    required this.title,
    required this.path,
    required this.fields,
    this.initial = const {},
    this.extra = const {},
    this.transform,
    this.patch = false,
    this.owner,
    this.draftId,
    this.explanation,
    super.key,
  });
  final String title, path;
  final List<TssaField> fields;
  final TssaData initial, extra;
  final TssaData Function(TssaData)? transform;
  final bool patch;
  final String? owner, draftId, explanation;
  @override
  ConsumerState<TssaFormScreen> createState() => _TssaFormState();
}

class _TssaFormState extends ConsumerState<TssaFormScreen> {
  final _form = GlobalKey<FormState>();
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};
  final _draftStorage = DraftStorage();
  bool _busy = false, _dirty = false, _loadingDraft = true;
  String? _error, _savedAt;
  String _key = TssaRepository.newKey();
  String? _lastPayload;
  Timer? _saveTimer;
  bool _leaving = false;
  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _saveTimer?.cancel();
    if (_dirty) {
      final keep = widget.owner != null && widget.draftId != null;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rời biểu mẫu?'),
          content: Text(
            keep
                ? 'Lưu bản nháp an toàn trên thiết bị và quay lại?'
                : 'Nội dung chưa gửi sẽ bị bỏ. Bạn muốn quay lại?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục sửa'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(keep ? 'Lưu nháp và quay lại' : 'Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (keep) {
        try {
          await _draftStorage.write(widget.owner!, widget.draftId!, {
            'values': _values,
            'key': _key,
            'lastPayload': _lastPayload,
          });
        } catch (_) {
          if (mounted) {
            setState(
              () => _error =
                  'Chưa lưu được bản nháp. Hãy tiếp tục sửa hoặc gửi khi có kết nối.',
            );
          }
          return;
        }
      }
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _values[field.key] =
          widget.initial[field.key] ??
          field.value ??
          (field.kind == 'bool'
              ? false
              : ['multi', 'ordered', 'windows', 'list'].contains(field.kind)
              ? <dynamic>[]
              : '');
    }
    _restore();
  }

  Future<void> _restore() async {
    try {
      if (widget.owner != null && widget.draftId != null) {
        final draft = await _draftStorage.read(widget.owner!, widget.draftId!);
        if (draft != null && mounted) {
          _values.addAll(Map<String, dynamic>.from(draft['values'] as Map));
          _key = draft['key'] as String;
          _lastPayload = draft['lastPayload'] as String?;
          _savedAt = 'Đã khôi phục bản nháp trên thiết bị';
          _dirty = true;
        }
      }
    } catch (_) {
      _error =
          'Thiết bị chưa thể mở kho bản nháp an toàn. Dữ liệu hiện tại vẫn chưa gửi.';
    }
    if (mounted) setState(() => _loadingDraft = false);
  }

  void _changed(String key, dynamic value) {
    setState(() {
      _values[key] = value;
      _dirty = true;
    });
    _saveTimer?.cancel();
    if (widget.owner != null && widget.draftId != null) {
      _saveTimer = Timer(const Duration(milliseconds: 400), _saveDraft);
    }
  }

  Future<void> _saveDraft() async {
    try {
      if (widget.owner != null && widget.draftId != null) {
        await _draftStorage.write(widget.owner!, widget.draftId!, {
          'values': _values,
          'key': _key,
          'lastPayload': _lastPayload,
        });
        if (mounted) {
          setState(
            () => _savedAt =
                'Đã lưu nháp an toàn trên thiết bị · hết hạn sau 24 giờ',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa lưu được bản nháp an toàn. Giữ màn hình mở để tiếp tục sửa.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _saveTimer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = {
        ...widget.extra,
        ...(widget.transform?.call(Map.of(_values)) ?? _values),
      };
      final encoded = jsonEncode(body);
      if (_lastPayload != null && _lastPayload != encoded) {
        _key = TssaRepository.newKey();
      }
      _lastPayload = encoded;
      await _saveDraft();
      await ref
          .read(tssaRepositoryProvider)
          .write(widget.path, body, patch: widget.patch, key: _key);
      if (widget.owner != null && widget.draftId != null) {
        await _draftStorage.remove(widget.owner!, widget.draftId!);
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _leaving = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Máy chủ đã xác nhận lưu.')));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (mounted) setState(() => _error = tssaError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(String key, String label, {dynamic existing}) async {
    final date =
        DateTime.tryParse(
          (existing ?? _values[key])?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (time == null || !mounted) return;
    _changed(
      key,
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      ).toUtc().toIso8601String(),
    );
  }

  Widget _field(TssaField field) {
    final required =
        field.required ||
        (field.requiredWhenKey != null &&
            _values[field.requiredWhenKey] == field.requiredWhenValue);
    final value = _values[field.key];
    if (field.kind == 'bool') {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: value == true,
        onChanged: _busy ? null : (v) => _changed(field.key, v),
      );
    }
    if (field.kind == 'select') {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value is String && field.options.containsKey(value)
            ? value
            : null,
        decoration: InputDecoration(
          labelText: '${field.label}${required ? ' *' : ''}',
        ),
        items: field.options.entries
            .map(
              (option) => DropdownMenuItem(
                value: option.key,
                child: Text(option.value),
              ),
            )
            .toList(),
        onChanged: _busy ? null : (v) => _changed(field.key, v),
        validator: (v) =>
            required && (v == null || v.isEmpty) ? 'Chọn ${field.label}' : null,
      );
    }
    if (['multi', 'ordered'].contains(field.kind)) {
      return FormField<List>(
        initialValue: (value as List?) ?? [],
        validator: (_) => required && (_values[field.key] as List).isEmpty
            ? 'Chọn ít nhất một mục.'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${field.label}${required ? ' *' : ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 8,
              children: field.options.entries
                  .map(
                    (option) => FilterChip(
                      label: Text(option.value),
                      selected: (_values[field.key] as List).contains(
                        option.key,
                      ),
                      onSelected: _busy
                          ? null
                          : (selected) {
                              final choices = List<String>.from(
                                _values[field.key] as List,
                              );
                              selected
                                  ? choices.add(option.key)
                                  : choices.remove(option.key);
                              _changed(field.key, choices);
                              state.didChange(choices);
                            },
                    ),
                  )
                  .toList(),
            ),
            if (field.kind == 'ordered') ...[
              const Text('Thứ tự giới thiệu: dùng nút lên/xuống để thay đổi.'),
              for (var i = 0; i < (_values[field.key] as List).length; i++)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i + 1}. ${field.options[(_values[field.key] as List)[i]] ?? (_values[field.key] as List)[i]}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đưa lên trước',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _busy || i == 0
                          ? null
                          : () {
                              final choices = List<String>.from(
                                _values[field.key] as List,
                              );
                              final selected = choices.removeAt(i);
                              choices.insert(i - 1, selected);
                              _changed(field.key, choices);
                              state.didChange(choices);
                            },
                    ),
                    IconButton(
                      tooltip: 'Đưa xuống sau',
                      icon: const Icon(Icons.arrow_downward),
                      onPressed:
                          _busy || i == (_values[field.key] as List).length - 1
                          ? null
                          : () {
                              final choices = List<String>.from(
                                _values[field.key] as List,
                              );
                              final selected = choices.removeAt(i);
                              choices.insert(i + 1, selected);
                              _changed(field.key, choices);
                              state.didChange(choices);
                            },
                    ),
                  ],
                ),
            ],
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    }
    if (field.kind == 'date') {
      return FormField<String>(
        validator: (_) =>
            required && (_values[field.key]?.toString() ?? '').isEmpty
            ? 'Chọn ${field.label}'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pickDate(field.key, field.label),
              icon: const Icon(Icons.event),
              label: Text('${field.label}: ${tssaDate(_values[field.key])}'),
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    }
    if (field.kind == 'windows') {
      return FormField<List>(
        validator: (_) => required && (_values[field.key] as List).isEmpty
            ? 'Thêm khoảng thời gian rảnh.'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${field.label}${required ? ' *' : ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Text(
              'Giờ trên thiết bị; máy chủ lưu UTC. Chỉ thêm thời gian bạn có thể tham gia.',
            ),
            for (var i = 0; i < (_values[field.key] as List).length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${tssaDate((_values[field.key] as List)[i]['start'])}\n${tssaDate((_values[field.key] as List)[i]['end'])}',
                ),
                trailing: IconButton(
                  tooltip: 'Xóa khoảng giờ',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy
                      ? null
                      : () {
                          final windows = List<dynamic>.from(
                            _values[field.key] as List,
                          )..removeAt(i);
                          _changed(field.key, windows);
                          state.didChange(windows);
                        },
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm khoảng giờ'),
              onPressed: _busy
                  ? null
                  : () async {
                      final startDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime(2100),
                      );
                      if (startDate == null || !mounted) return;
                      final startTime = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (startTime == null || !mounted) return;
                      final endDate = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: startDate,
                        lastDate: DateTime(2100),
                      );
                      if (endDate == null || !mounted) return;
                      final endTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: (startTime.hour + 1).clamp(0, 23),
                          minute: startTime.minute,
                        ),
                      );
                      if (endTime == null || !mounted) return;
                      final start = DateTime(
                        startDate.year,
                        startDate.month,
                        startDate.day,
                        startTime.hour,
                        startTime.minute,
                      ).toUtc();
                      final end = DateTime(
                        endDate.year,
                        endDate.month,
                        endDate.day,
                        endTime.hour,
                        endTime.minute,
                      ).toUtc();
                      if (!end.isAfter(start)) {
                        setState(
                          () => _error = 'Giờ kết thúc cần sau giờ bắt đầu.',
                        );
                        return;
                      }
                      final windows = [
                        ...(_values[field.key] as List),
                        {
                          'start': start.toIso8601String(),
                          'end': end.toIso8601String(),
                        },
                      ];
                      _changed(field.key, windows);
                      state.didChange(windows);
                    },
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    }
    final controller = _controllers.putIfAbsent(
      field.key,
      () => TextEditingController(
        text: field.kind == 'list'
            ? (value as List).join(', ')
            : value?.toString() ?? '',
      ),
    );
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      obscureText: field.kind == 'password',
      minLines: field.kind == 'long' ? 3 : 1,
      maxLines: field.kind == 'long' ? 8 : 1,
      keyboardType: field.kind == 'number'
          ? TextInputType.number
          : field.kind == 'long'
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: '${field.label}${required ? ' *' : ''}',
        helperText: field.hint,
        helperMaxLines: 4,
        alignLabelWithHint: true,
      ),
      onChanged: (v) => _changed(
        field.key,
        field.kind == 'list'
            ? v
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
            : field.kind == 'number'
            ? int.tryParse(v)
            : v,
      ),
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? 'Nhập ${field.label}'
          : field.kind == 'number' &&
                v?.isNotEmpty == true &&
                int.tryParse(v!) == null
          ? 'Nhập số nguyên.'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _busy ? null : _leave,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loadingDraft
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.explanation != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(widget.explanation!),
                    ),
                  for (final field in widget.fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _field(field),
                    ),
                  if (_savedAt != null)
                    Text(
                      _savedAt!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: Icon(_busy ? Icons.hourglass_top : Icons.check),
                    label: Text(_busy ? 'Chờ máy chủ xác nhận…' : 'Lưu và gửi'),
                  ),
                  if (widget.draftId != null)
                    TextButton(
                      onPressed: _busy ? null : _saveDraft,
                      child: const Text('Lưu nháp trên thiết bị'),
                    ),
                ],
              ),
            ),
    ),
  );
}

String tssaDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return 'Chưa chọn';
  String two(int n) => n.toString().padLeft(2, '0');
  final offset = date.timeZoneOffset;
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)} (UTC${offset.isNegative ? '-' : '+'}${two(offset.inHours.abs())}:${two(offset.inMinutes.abs() % 60)})';
}
