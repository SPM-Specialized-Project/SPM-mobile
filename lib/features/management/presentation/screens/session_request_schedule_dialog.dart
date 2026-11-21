import 'package:flutter/material.dart';

import '../../../learning/domain/session_request.dart';

class SessionScheduleDraft {
  const SessionScheduleDraft({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.method,
    required this.link,
    required this.location,
  });

  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String method;
  final String link;
  final String location;
}

Future<SessionScheduleDraft?> showSessionRequestScheduleDialog(
  BuildContext context,
  SessionRequest request,
) => showDialog<SessionScheduleDraft>(
  context: context,
  builder: (_) => _SessionRequestScheduleDialog(request: request),
);

class _SessionRequestScheduleDialog extends StatefulWidget {
  const _SessionRequestScheduleDialog({required this.request});

  final SessionRequest request;

  @override
  State<_SessionRequestScheduleDialog> createState() =>
      _SessionRequestScheduleDialogState();
}

class _SessionRequestScheduleDialogState
    extends State<_SessionRequestScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  final _link = TextEditingController();
  final _location = TextEditingController();
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _method = 'online';
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.request.title);
    _description = TextEditingController(text: widget.request.description);
    final requestedStart = widget.request.proposedAt.toLocal();
    final now = DateTime.now();
    final start = requestedStart.isAfter(now)
        ? requestedStart
        : now.add(const Duration(days: 1));
    _date = DateTime(start.year, start.month, start.day);
    _startTime = TimeOfDay.fromDateTime(start);
    final end = start.add(const Duration(hours: 1));
    _endTime = TimeOfDay(
      hour: end.day == start.day ? end.hour : 23,
      minute: end.day == start.day ? end.minute : 59,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    _location.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay time) =>
      DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: const Text('Xếp lịch cho yêu cầu'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.courseTitle),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _title,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Tên buổi học'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Nhập tên buổi học.'
                      : null,
                ),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(localizations.formatMediumDate(_date)),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: true),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('Bắt đầu ${_startTime.format(context)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('Kết thúc ${_endTime.format(context)}'),
                    ),
                  ],
                ),
                Text(
                  'Thời lượng ban đầu là 60 phút; bạn có thể đổi giờ kết thúc.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _timeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Hình thức'),
                  items: const [
                    DropdownMenuItem(
                      value: 'online',
                      child: Text('Trực tuyến'),
                    ),
                    DropdownMenuItem(
                      value: 'offline',
                      child: Text('Trực tiếp'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _method = value);
                  },
                ),
                const SizedBox(height: 8),
                if (_method == 'online')
                  TextFormField(
                    controller: _link,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Liên kết buổi học',
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      final uri = Uri.tryParse(text);
                      return uri != null &&
                              uri.hasAuthority &&
                              (uri.scheme == 'https' || uri.scheme == 'http')
                          ? null
                          : 'Nhập liên kết bắt đầu bằng http:// hoặc https://.';
                    },
                  )
                else
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: 'Địa điểm'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Nhập địa điểm buổi học.'
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Tạo lịch')),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) {
      setState(
        () => _date = DateTime(selected.year, selected.month, selected.day),
      );
    }
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected != null) {
      setState(() {
        if (isStart) {
          _startTime = selected;
        } else {
          _endTime = selected;
        }
        _timeError = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final start = _at(_startTime);
    final end = _at(_endTime);
    if (!start.isAfter(DateTime.now()) || !end.isAfter(start)) {
      setState(
        () => _timeError =
            'Chọn giờ bắt đầu trong tương lai và giờ kết thúc sau giờ bắt đầu.',
      );
      return;
    }
    Navigator.pop(
      context,
      SessionScheduleDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        start: start,
        end: end,
        method: _method,
        link: _link.text.trim(),
        location: _location.text.trim(),
      ),
    );
  }
}
