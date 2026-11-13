import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../auth/data/auth_session.dart';
import '../../application/management_providers.dart';
import '../../../learning/domain/class_session.dart';
import '../../../learning/domain/course.dart';
import '../../../learning/presentation/widgets/session_month_navigator.dart';
import '../widgets/management_common.dart';

class ManagerSessionsScreen extends ConsumerStatefulWidget {
  const ManagerSessionsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  ConsumerState<ManagerSessionsScreen> createState() =>
      _ManagerSessionsScreenState();
}

class _ManagerSessionsScreenState extends ConsumerState<ManagerSessionsScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _moveMonth(int offset) => setState(
    () => _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    ),
  );

  @override
  Widget build(BuildContext context) {
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
        final monthSessions = sorted
            .where((item) => isInSessionMonth(item.start, _visibleMonth))
            .toList(growable: false);
        final monthKey = '${_visibleMonth.year}-${_visibleMonth.month}';
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
                      'Xem lịch theo tháng; thao tác từng buổi phụ thuộc quyền được cấp.',
                ),
                const SizedBox(height: 8),
                SessionMonthNavigator(
                  month: _visibleMonth,
                  sessionCount: monthSessions.length,
                  onPrevious: () => _moveMonth(-1),
                  onNext: () => _moveMonth(1),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: AppMotion.duration(context),
                  transitionBuilder: (child, animation) =>
                      AppMotion.pageTransition(context, child, animation),
                  child: monthSessions.isEmpty
                      ? SizedBox(
                          key: ValueKey('$monthKey:empty'),
                          height: 240,
                          child: ManagementEmpty(
                            title: sorted.isEmpty
                                ? 'Chưa có lịch'
                                : 'Tháng này chưa có buổi học',
                            message: sorted.isEmpty
                                ? 'Tạo buổi học đầu tiên cho một khóa học.'
                                : 'Chọn tháng khác để xem lịch đã tạo.',
                          ),
                        )
                      : Column(
                          key: ValueKey('$monthKey:items'),
                          children: [
                            for (final item in monthSessions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SessionCard(
                                  session: item,
                                  onEdit: item.canManageUpcoming
                                      ? () => _editSession(context, item)
                                      : null,
                                  onCancel: item.canManageUpcoming
                                      ? () => _cancelSession(context, item)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                ),
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
        builder: (_) =>
            _CreateSessionForm(courses: courses, session: widget.session),
      );
      if (saved == true) ref.invalidate(managerSessionsProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }

  Future<void> _editSession(BuildContext context, ClassSession item) async {
    try {
      final courses = await ref.read(managerCoursesProvider.future);
      if (!context.mounted) return;
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _CreateSessionForm(
          courses: courses,
          session: widget.session,
          initialSession: item,
        ),
      );
      if (saved == true) {
        ref.invalidate(managerSessionsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thay đổi buổi học.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }

  Future<void> _cancelSession(BuildContext context, ClassSession item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy buổi học?'),
        content: Text(
          '“${item.title}” sẽ chuyển sang trạng thái Đã hủy và không còn cho phép chỉnh sửa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(managementRepositoryProvider)
          .updateSessionStatus(item.id, 'cancelled');
      ref.invalidate(managerSessionsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy buổi học.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onEdit, this.onCancel});

  final ClassSession session;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

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
            if (onEdit != null || onCancel != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (onEdit != null)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Chỉnh sửa'),
                    ),
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Hủy buổi'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateSessionForm extends ConsumerStatefulWidget {
  const _CreateSessionForm({
    required this.courses,
    required this.session,
    this.initialSession,
  });

  final List<Course> courses;
  final AuthSession session;
  final ClassSession? initialSession;

  @override
  ConsumerState<_CreateSessionForm> createState() => _CreateSessionFormState();
}

class _CreateSessionFormState extends ConsumerState<_CreateSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _link = TextEditingController();
  final _location = TextEditingController();
  late String _courseId;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _method;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialSession;
    _courseId = existing?.courseId ?? widget.courses.first.id;
    _method = existing?.method.toLowerCase() ?? 'online';
    if (existing == null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      return;
    }
    final start = existing.start.toLocal();
    final end = existing.end.toLocal();
    _date = DateTime(start.year, start.month, start.day);
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = TimeOfDay.fromDateTime(end);
    _title.text = existing.title;
    _description.text = existing.description;
    _link.text = existing.link ?? '';
    _location.text = existing.location ?? '';
  }

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
                widget.initialSession == null
                    ? 'Tạo buổi học'
                    : 'Chỉnh sửa buổi học',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              if (widget.initialSession == null)
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
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _courseId = value);
                        },
                )
              else
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Khóa học'),
                  child: Text(widget.initialSession!.courseTitle),
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
                onChanged: _saving
                    ? null
                    : (value) {
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
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _chooseDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _chooseTime(isStart: true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Bắt đầu ${_startTime.format(context)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _chooseTime(isStart: false),
                    icon: const Icon(Icons.schedule),
                    label: Text('Kết thúc ${_endTime.format(context)}'),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
                      : Text(
                          widget.initialSession == null
                              ? 'Tạo lịch'
                              : 'Lưu thay đổi',
                        ),
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
    if (!start.isAfter(DateTime.now())) {
      setState(() => _errorMessage = 'Thời gian bắt đầu phải ở tương lai.');
      return;
    }
    if (!end.isAfter(start)) {
      setState(() => _errorMessage = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(managementRepositoryProvider);
      if (widget.initialSession case final existing?) {
        await repository.updateSession(
          id: existing.id,
          title: _title.text,
          description: _description.text,
          start: start,
          end: end,
          method: _method,
          link: _method == 'online' ? _link.text : null,
          location: _method == 'offline' ? _location.text : null,
        );
      } else {
        final course = widget.courses.firstWhere(
          (item) => item.id == _courseId,
        );
        await repository.createSession(
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
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = managementErrorMessage(error);
      });
    }
  }
}
