import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_session.dart';
import '../../application/management_providers.dart';
import '../../../learning/domain/class_session.dart';
import '../../../learning/domain/course.dart';
import '../widgets/management_common.dart';

class ManagerSessionsScreen extends ConsumerWidget {
  const ManagerSessionsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerSessionsProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(managerSessionsProvider),
      ),
      data: (sessions) {
        final sorted = [...sessions]
          ..sort((a, b) => a.start.compareTo(b.start));
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createSession(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo buổi học'),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(managerSessionsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                const ManagementPageHeader(
                  title: 'Lịch điều phối',
                  subtitle:
                      'Xem lịch và tạo buổi cho khóa học. Backend quản lý quyền chỉnh sửa/xóa từng buổi.',
                ),
                if (sorted.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: ManagementEmpty(
                      title: 'Chưa có lịch',
                      message: 'Tạo buổi học đầu tiên cho một khóa học.',
                    ),
                  )
                else
                  for (final item in sorted) ...[
                    _SessionCard(session: item),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createSession(BuildContext context, WidgetRef ref) async {
    try {
      final courses = await ref.read(managerCoursesProvider.future);
      if (!context.mounted) return;
      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend chưa cung cấp khóa học để chọn.'),
          ),
        );
        return;
      }
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _CreateSessionForm(courses: courses, session: session),
      );
      if (saved == true) ref.invalidate(managerSessionsProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final start = session.start.toLocal();
    final end = session.end.toLocal();
    final date =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
    final time =
        '${TimeOfDay.fromDateTime(start).format(context)} – ${TimeOfDay.fromDateTime(end).format(context)}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ManagementStatus(status: session.status),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              session.courseTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text('$date · $time'),
            Text(
              session.method == 'online'
                  ? 'Trực tuyến'
                  : (session.location ?? 'Trực tiếp'),
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(session.description),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateSessionForm extends ConsumerStatefulWidget {
  const _CreateSessionForm({required this.courses, required this.session});

  final List<Course> courses;
  final AuthSession session;

  @override
  ConsumerState<_CreateSessionForm> createState() => _CreateSessionFormState();
}

class _CreateSessionFormState extends ConsumerState<_CreateSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _link = TextEditingController();
  final _location = TextEditingController();
  late String _courseId = widget.courses.first.id;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _method = 'online';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, keyboard + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tạo buổi học',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _courseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Khóa học'),
                items: [
                  for (final course in widget.courses)
                    DropdownMenuItem(
                      value: course.id,
                      child: Text(
                        '${course.code} · ${course.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _courseId = value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Tên buổi học'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nhập tên buổi học.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Hình thức'),
                items: const [
                  DropdownMenuItem(value: 'online', child: Text('Trực tuyến')),
                  DropdownMenuItem(value: 'offline', child: Text('Trực tiếp')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 10),
              if (_method == 'online')
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Liên kết phòng học',
                    hintText: 'https://…',
                  ),
                ),
              if (_method == 'offline')
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Địa điểm'),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _chooseTime(isStart: true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Bắt đầu ${_startTime.format(context)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _chooseTime(isStart: false),
                    icon: const Icon(Icons.schedule),
                    label: Text('Kết thúc ${_endTime.format(context)}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                      : const Text('Tạo lịch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (value != null) {
      setState(() {
        if (isStart) {
          _startTime = value;
        } else {
          _endTime = value;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final course = widget.courses.firstWhere((item) => item.id == _courseId);
      await ref
          .read(managementRepositoryProvider)
          .createSession(
            course: course,
            session: widget.session,
            title: _title.text,
            description: _description.text,
            start: start,
            end: end,
            method: _method,
            link: _link.text,
            location: _location.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }
}
