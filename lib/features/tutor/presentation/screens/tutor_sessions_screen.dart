import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_session.dart';
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

class _SessionsList extends ConsumerWidget {
  const _SessionsList({required this.session, required this.sessions});

  final AuthSession session;
  final List<TutorSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedSessions = [...sessions]
      ..sort((left, right) => left.start.compareTo(right.start));
    final now = DateTime.now();
    final upcomingCount = sortedSessions
        .where((item) => item.start.isAfter(now) && item.status != 'cancelled')
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSession(context, ref),
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
                subtitle: 'Theo dõi các buổi do tài khoản tutor tạo.',
                trailing: _UpcomingCount(count: upcomingCount),
              ),
              const SizedBox(height: 20),
              if (sortedSessions.isEmpty)
                const SizedBox(
                  height: 300,
                  child: TutorEmptyView(
                    icon: Icons.event_available_outlined,
                    title: 'Chưa có buổi học',
                    message:
                        'Tạo buổi đầu tiên cho một khóa học bạn được phân công.',
                  ),
                )
              else
                for (final session in sortedSessions) ...[
                  _TutorSessionCard(session: session),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSession(BuildContext context, WidgetRef ref) async {
    try {
      final courses = await ref.read(tutorCoursesProvider.future);
      if (!context.mounted) return;
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
            _CreateTutorSessionSheet(courses: courses, session: session),
      );

      if (created == true) {
        ref.invalidate(tutorSessionsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã tạo buổi học.')));
      }
    } catch (error) {
      if (!context.mounted) return;
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
  const _TutorSessionCard({required this.session});

  final TutorSession session;

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
  });

  final List<TutorCourse> courses;
  final AuthSession session;

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

  late String _courseId = widget.courses.first.id;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _method = 'online';
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_start.isAfter(DateTime.now())) {
      setState(() => _errorMessage = 'Thời gian bắt đầu phải ở tương lai.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final course = widget.courses.firstWhere((item) => item.id == _courseId);
      await ref
          .read(tutorRepositoryProvider)
          .createSession(
            course: course,
            session: widget.session,
            title: _titleController.text,
            description: _descriptionController.text,
            start: _start,
            end: _start.add(const Duration(hours: 1)),
            method: _method,
            link: _method == 'online' ? _linkController.text : null,
            location: _method == 'offline' ? _locationController.text : null,
          );
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
                'Tạo buổi học',
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
                    onChanged: _saving
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(_formatDate(_date)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(_time.format(context)),
                    ),
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
                  validator: (value) {
                    final uri = Uri.tryParse(value?.trim() ?? '');
                    if (uri == null ||
                        !['http', 'https'].contains(uri.scheme) ||
                        uri.host.isEmpty) {
                      return 'Nhập link bắt đầu bằng http:// hoặc https://.';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Phòng / địa điểm',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Nhập địa điểm học.'
                      : null,
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
                label: Text(_saving ? 'Đang lưu...' : 'Tạo buổi học'),
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
