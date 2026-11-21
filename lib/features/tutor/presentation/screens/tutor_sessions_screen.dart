import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../auth/data/auth_session.dart';
import '../../../learning/presentation/widgets/session_month_navigator.dart';
import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../../domain/tutor_session.dart';
import '../widgets/tutor_ui.dart';

class TutorSessionsScreen extends ConsumerWidget {
  const TutorSessionsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(tutorSessionsProvider);

    return sessionsState.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(tutorSessionsProvider),
      ),
      data: (sessions) => _SessionsList(session: session, sessions: sessions),
    );
  }
}

class _SessionsList extends ConsumerStatefulWidget {
  const _SessionsList({required this.session, required this.sessions});

  final AuthSession session;
  final List<TutorSession> sessions;

  @override
  ConsumerState<_SessionsList> createState() => _SessionsListState();
}

class _SessionsListState extends ConsumerState<_SessionsList> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _moveMonth(int offset) => setState(
    () => _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sortedSessions = [...widget.sessions]
      ..sort((left, right) => left.start.compareTo(right.start));
    final monthSessions = sortedSessions
        .where((item) => isInSessionMonth(item.start, _visibleMonth))
        .toList(growable: false);
    final now = DateTime.now();
    final upcomingCount = sortedSessions
        .where((item) => item.start.isAfter(now) && item.status != 'cancelled')
        .length;
    final monthKey = '${_visibleMonth.year}-${_visibleMonth.month}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSession,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo buổi học'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(tutorSessionsProvider.future).then<void>((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              TutorPageHeading(
                title: 'Lịch dạy',
                subtitle: 'Xem lịch theo tháng và quản lý các buổi sắp tới.',
                trailing: _UpcomingCount(count: upcomingCount),
              ),
              const SizedBox(height: 16),
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
                        height: 250,
                        child: TutorEmptyView(
                          icon: Icons.event_available_outlined,
                          title: sortedSessions.isEmpty
                              ? 'Chưa có buổi học'
                              : 'Tháng này chưa có buổi học',
                          message: sortedSessions.isEmpty
                              ? 'Tạo buổi đầu tiên cho một khóa học bạn được phân công.'
                              : 'Chọn tháng khác để xem lịch đã tạo.',
                        ),
                      )
                    : Column(
                        key: ValueKey('$monthKey:items'),
                        children: [
                          for (final item in monthSessions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TutorSessionCard(
                                session: item,
                                onEdit: item.canManageUpcoming
                                    ? () => _editSession(item)
                                    : null,
                                onCancel: item.canManageUpcoming
                                    ? () => _cancelSession(item)
                                    : null,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSession() async {
    try {
      final courses = await ref.read(tutorCoursesProvider.future);
      if (!mounted) return;
      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa được phân công khóa học.')),
        );
        return;
      }

      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) =>
            _CreateTutorSessionSheet(courses: courses, session: widget.session),
      );

      if (created == true) {
        ref.invalidate(tutorSessionsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã tạo buổi học.')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }

  Future<void> _editSession(TutorSession item) async {
    try {
      final courses = await ref.read(tutorCoursesProvider.future);
      if (!mounted) return;
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _CreateTutorSessionSheet(
          courses: courses,
          session: widget.session,
          initialSession: item,
        ),
      );
      if (saved == true) {
        ref.invalidate(tutorSessionsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thay đổi buổi học.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }

  Future<void> _cancelSession(TutorSession item) async {
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
          .read(tutorRepositoryProvider)
          .updateSessionStatus(item.id, 'cancelled');
      ref.invalidate(tutorSessionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy buổi học.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }
}

class _UpcomingCount extends StatelessWidget {
  const _UpcomingCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$count sắp tới',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TutorSessionCard extends StatelessWidget {
  const _TutorSessionCard({required this.session, this.onEdit, this.onCancel});

  final TutorSession session;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final localStart = session.start.toLocal();
    final localEnd = session.end.toLocal();
    final date =
        '${localStart.day.toString().padLeft(2, '0')}/'
        '${localStart.month.toString().padLeft(2, '0')}/${localStart.year}';
    final timeRange =
        '${TimeOfDay.fromDateTime(localStart).format(context)}'
        ' – ${TimeOfDay.fromDateTime(localEnd).format(context)}';
    final isOnline = session.method.toLowerCase() == 'online';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
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
                    session.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TutorStatusPill(status: session.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              session.courseTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _SessionDetail(
                  icon: Icons.calendar_today_outlined,
                  value: date,
                ),
                _SessionDetail(icon: Icons.schedule_rounded, value: timeRange),
                _SessionDetail(
                  icon: isOnline
                      ? Icons.videocam_outlined
                      : Icons.place_outlined,
                  value: isOnline
                      ? 'Trực tuyến'
                      : session.location ?? 'Trực tiếp',
                ),
              ],
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CreateTutorSessionSheet extends ConsumerStatefulWidget {
  const _CreateTutorSessionSheet({
    required this.courses,
    required this.session,
    this.initialSession,
  });

  final List<TutorCourse> courses;
  final AuthSession session;
  final TutorSession? initialSession;

  @override
  ConsumerState<_CreateTutorSessionSheet> createState() =>
      _CreateTutorSessionSheetState();
}

class _CreateTutorSessionSheetState
    extends ConsumerState<_CreateTutorSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();

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
    _titleController.text = existing.title;
    _descriptionController.text = existing.description;
    _linkController.text = existing.link ?? '';
    _locationController.text = existing.location ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _startTime.hour,
    _startTime.minute,
  );
  DateTime get _end => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _endTime.hour,
    _endTime.minute,
  );

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_start.isAfter(DateTime.now())) {
      setState(() => _errorMessage = 'Thời gian bắt đầu phải ở tương lai.');
      return;
    }
    if (!_end.isAfter(_start)) {
      setState(() => _errorMessage = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(tutorRepositoryProvider);
      if (widget.initialSession case final existing?) {
        await repository.updateSession(
          id: existing.id,
          title: _titleController.text,
          description: _descriptionController.text,
          start: _start,
          end: _end,
          method: _method,
          link: _method == 'online' ? _linkController.text : null,
          location: _method == 'offline' ? _locationController.text : null,
        );
      } else {
        final course = widget.courses.firstWhere(
          (item) => item.id == _courseId,
        );
        await repository.createSession(
          course: course,
          session: widget.session,
          title: _titleController.text,
          description: _descriptionController.text,
          start: _start,
          end: _end,
          method: _method,
          link: _method == 'online' ? _linkController.text : null,
          location: _method == 'offline' ? _locationController.text : null,
        );
      }
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
                widget.initialSession == null
                    ? 'Tạo buổi học'
                    : 'Chỉnh sửa buổi học',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Khóa học'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _courseId,
                    isExpanded: true,
                    items: [
                      for (final course in widget.courses)
                        DropdownMenuItem(
                          value: course.id,
                          child: Text(
                            '${course.title} (${course.code})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving || widget.initialSession != null
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _courseId = value);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Tên buổi học'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Nhập tên buổi học.'
                    : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _chooseDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_formatDate(_date)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _chooseTime(isStart: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Bắt đầu ${_startTime.format(context)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _chooseTime(isStart: false),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('Kết thúc ${_endTime.format(context)}'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'online',
                    icon: Icon(Icons.videocam_outlined),
                    label: Text('Trực tuyến'),
                  ),
                  ButtonSegment(
                    value: 'offline',
                    icon: Icon(Icons.place_outlined),
                    label: Text('Trực tiếp'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _method = selection.first),
              ),
              const SizedBox(height: 12),
              if (_method == 'online')
                TextFormField(
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link buổi học',
                    hintText: 'https://meet.example.com/...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                )
              else
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Phòng / địa điểm',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mô tả / nội dung chuẩn bị',
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
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving
                      ? 'Đang lưu...'
                      : widget.initialSession == null
                      ? 'Tạo buổi học'
                      : 'Lưu thay đổi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
