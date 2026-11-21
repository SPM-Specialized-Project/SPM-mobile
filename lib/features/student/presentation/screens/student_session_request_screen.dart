import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/course.dart';
import '../../../learning/domain/session_request.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import '../../data/local_session_request_store.dart';

enum _StudentRequestKind { newSession, makeup, absence }

class StudentSessionRequestScreen extends ConsumerStatefulWidget {
  const StudentSessionRequestScreen({required this.ownerId, super.key});

  final String ownerId;

  @override
  ConsumerState<StudentSessionRequestScreen> createState() =>
      _StudentSessionRequestScreenState();
}

class _StudentSessionRequestScreenState
    extends ConsumerState<StudentSessionRequestScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _courseId;
  bool _saving = false;
  DateTime _proposedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _proposedTime = const TimeOfDay(hour: 14, minute: 0);
  _StudentRequestKind _kind = _StudentRequestKind.newSession;

  Future<void> _saveDraft(Course? course) async {
    if (_saving) return;
    final title = _title.text.trim();
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa có khóa học để chọn.')),
      );
      return;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập tiêu đề yêu cầu.')),
      );
      return;
    }
    final proposedAt = DateTime(
      _proposedDate.year,
      _proposedDate.month,
      _proposedDate.day,
      _proposedTime.hour,
      _proposedTime.minute,
    );
    setState(() => _saving = true);
    final drafts = await LocalSessionRequestStore.load(widget.ownerId);
    drafts.insert(0, {
      'id': 'draft-${DateTime.now().microsecondsSinceEpoch}',
      'courseId': course.id,
      'courseTitle': course.title,
      'kind': _kind.name,
      'title': title,
      'description': _description.text.trim(),
      'proposedAt': proposedAt.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'draft',
    });
    try {
      await LocalSessionRequestStore.save(widget.ownerId, drafts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu bản nháp trên thiết bị; chưa gửi lên hệ thống.',
          ),
        ),
      );
      _title.clear();
      _description.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu bản nháp trên thiết bị.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendRequest(Course? course) async {
    if (_saving) return;
    final title = _title.text.trim();
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa có khóa học để chọn.')),
      );
      return;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập tiêu đề yêu cầu.')),
      );
      return;
    }
    final proposedAt = DateTime(
      _proposedDate.year,
      _proposedDate.month,
      _proposedDate.day,
      _proposedTime.hour,
      _proposedTime.minute,
    );
    if (!proposedAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian đề xuất phải ở tương lai.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(studentRepositoryProvider)
          .createSessionRequest(
            courseId: course.id,
            requestType: switch (_kind) {
              _StudentRequestKind.newSession => 'new',
              _StudentRequestKind.makeup => 'makeup',
              _StudentRequestKind.absence => 'absent',
            },
            title: title,
            description: _description.text.trim(),
            proposedAt: proposedAt,
          );
      if (!mounted) return;
      ref.invalidate(studentSessionRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu; đang chờ xử lý.')),
      );
      _title.clear();
      _description.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _proposedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _proposedDate = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _proposedTime,
    );
    if (selected != null) setState(() => _proposedTime = selected);
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(studentCoursesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu buổi học'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử yêu cầu',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    StudentSessionRequestHistoryScreen(ownerId: widget.ownerId),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: coursesState.when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(studentCoursesProvider),
        ),
        data: (courses) => _buildForm(context, courses),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Course> courses) {
    final colors = Theme.of(context).colorScheme;
    final selectedCourse = courses.where((course) => course.id == _courseId);
    final course = selectedCourse.firstOrNull ?? courses.firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Đề xuất lịch phù hợp',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          'Chia sẻ môn học, lý do và thời gian bạn mong muốn.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF755400)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gửi yêu cầu để giảng viên xử lý. Bản nháp vẫn chỉ lưu trên thiết bị và không được gửi đi.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: course?.id,
          decoration: const InputDecoration(
            labelText: 'Khóa học',
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          items: [
            for (final item in courses)
              DropdownMenuItem(value: item.id, child: Text(item.title)),
          ],
          onChanged: (value) => setState(() => _courseId = value),
        ),
        const SizedBox(height: 16),
        Text('Loại yêu cầu', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<_StudentRequestKind>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _StudentRequestKind.newSession,
              label: Text('Buổi mới'),
            ),
            ButtonSegment(
              value: _StudentRequestKind.makeup,
              label: Text('Học bù'),
            ),
            ButtonSegment(
              value: _StudentRequestKind.absence,
              label: Text('Xin vắng'),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (selection) =>
              setState(() => _kind = selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            hintText: 'Ví dụ: Ôn tập trước kỳ thi',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(_proposedDate),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _chooseTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(_proposedTime.format(context)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _description,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Mô tả thêm',
            hintText: 'Nêu nội dung cần hỗ trợ hoặc lý do xin vắng.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : () => _sendRequest(course),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_saving ? 'Đang gửi…' : 'Gửi yêu cầu'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _saveDraft(course),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu bản nháp trên thiết bị'),
        ),
      ],
    );
  }
}

class StudentSessionRequestHistoryScreen extends ConsumerStatefulWidget {
  const StudentSessionRequestHistoryScreen({required this.ownerId, super.key});

  final String ownerId;

  @override
  ConsumerState<StudentSessionRequestHistoryScreen> createState() =>
      _StudentSessionRequestHistoryScreenState();
}

class _StudentSessionRequestHistoryScreenState
    extends ConsumerState<StudentSessionRequestHistoryScreen> {
  List<Map<String, dynamic>> _drafts = const [];
  bool _loadingDrafts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drafts = await LocalSessionRequestStore.load(widget.ownerId);
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _loadingDrafts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(studentSessionRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử yêu cầu')),
      body: SafeArea(
        child: requestsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildHistory(
            context,
            const [],
            errorMessage: tutorErrorMessage(error),
          ),
          data: (requests) => _buildHistory(context, requests),
        ),
      ),
    );
  }

  Widget _buildHistory(
    BuildContext context,
    List<SessionRequest> requests, {
    String? errorMessage,
  }) {
    final sortedRequests = [...requests]
      ..sort(
        (left, right) =>
            right.createdAt?.compareTo(left.createdAt ?? DateTime(0)) ?? 0,
      );
    if (sortedRequests.isEmpty &&
        _drafts.isEmpty &&
        errorMessage == null &&
        !_loadingDrafts) {
      return const TutorEmptyView(
        icon: Icons.history_rounded,
        title: 'Chưa có yêu cầu',
        message: 'Yêu cầu đã gửi và bản nháp trên thiết bị sẽ hiển thị ở đây.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .refresh(studentSessionRequestsProvider.future)
            .then<void>((_) {});
        await _load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
        children: [
          if (errorMessage != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(errorMessage),
              ),
            ),
          _historyNotice(context),
          if (sortedRequests.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Đã gửi lên hệ thống',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final request in sortedRequests) ...[
              _SessionRequestCard(
                title: request.title,
                courseTitle: request.courseTitle,
                requestType: request.requestType,
                status: request.status,
                proposedAt: request.proposedAt,
                scheduledStart: request.scheduledStart,
                scheduledEnd: request.scheduledEnd,
                onTap: () => _showRequestDetails(context, request),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (_loadingDrafts)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Bản nháp trên thiết bị',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final draft in _drafts) ...[
              _SessionRequestCard(
                title: draft['title'] as String? ?? 'Yêu cầu',
                courseTitle: draft['courseTitle'] as String? ?? 'Khóa học',
                requestType: draft['kind'] as String? ?? 'newSession',
                status: 'draft',
                proposedAt: DateTime.tryParse(
                  draft['proposedAt'] as String? ?? '',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _historyNotice(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Yêu cầu đã gửi có trạng thái từ máy chủ. Bản nháp chỉ lưu trên thiết bị và chưa được gửi cho giảng viên.',
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }

  Future<void> _showRequestDetails(
    BuildContext context,
    SessionRequest request,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            request.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(request.courseTitle),
          const SizedBox(height: 12),
          _SessionRequestCard(
            title: request.title,
            courseTitle: request.courseTitle,
            requestType: request.requestType,
            status: request.status,
            proposedAt: request.proposedAt,
            scheduledStart: request.scheduledStart,
            scheduledEnd: request.scheduledEnd,
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(request.description),
          ],
          if (request.reviewReason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Phản hồi: ${request.reviewReason}'),
          ],
          if (request.scheduledSessionId != null) ...[
            const SizedBox(height: 14),
            Text('Mã buổi học: ${request.scheduledSessionId}'),
          ],
        ],
      ),
    ),
  );
}

class _SessionRequestCard extends StatelessWidget {
  const _SessionRequestCard({
    required this.title,
    required this.courseTitle,
    required this.requestType,
    required this.status,
    required this.proposedAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.onTap,
  });

  final String title;
  final String courseTitle;
  final String requestType;
  final String status;
  final DateTime? proposedAt;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final statusLabel = switch (status.toLowerCase()) {
      'pending' => 'Đang chờ',
      'scheduling' => 'Đang xếp lịch',
      'scheduled' => 'Đã lên lịch',
      'approved' => 'Đã duyệt',
      'declined' => 'Từ chối',
      _ => 'Bản nháp',
    };
    final typeLabel = switch (requestType) {
      'makeup' => 'Học bù',
      'absent' || 'absence' => 'Xin vắng',
      _ => 'Buổi mới',
    };
    final displayedTime = scheduledStart ?? proposedAt;
    final scheduledTime = scheduledStart == null
        ? null
        : '${TimeOfDay.fromDateTime(scheduledStart!.toLocal()).format(context)}'
              '${scheduledEnd == null ? '' : '–${TimeOfDay.fromDateTime(scheduledEnd!.toLocal()).format(context)}'}';
    final timeLabel = displayedTime == null
        ? 'Chưa chọn thời gian'
        : '${scheduledStart == null ? 'Mong muốn' : 'Đã xếp'}: '
              '${localizations.formatMediumDate(displayedTime.toLocal())} · '
              '${scheduledTime ?? TimeOfDay.fromDateTime(displayedTime.toLocal()).format(context)}';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$courseTitle · $typeLabel\n$timeLabel'),
        isThreeLine: true,
        trailing: Chip(label: Text(statusLabel)),
      ),
    );
  }
}
