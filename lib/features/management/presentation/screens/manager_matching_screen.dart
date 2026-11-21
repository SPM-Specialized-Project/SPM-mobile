import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/class_session.dart';
import '../../application/management_providers.dart';
import '../../data/management_models.dart';
import '../widgets/management_common.dart';

enum _MatchingView { pendingRequests, scheduledSessions }

class ManagerMatchingScreen extends ConsumerStatefulWidget {
  const ManagerMatchingScreen({super.key});

  @override
  ConsumerState<ManagerMatchingScreen> createState() =>
      _ManagerMatchingScreenState();
}

class _ManagerMatchingScreenState extends ConsumerState<ManagerMatchingScreen> {
  final _searchController = TextEditingController();
  _MatchingView _view = _MatchingView.pendingRequests;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrations = ref.watch(managerRegistrationsProvider);
    final sessions = ref.watch(managerSessionsProvider);
    return registrations.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: _reload,
      ),
      data: (registrationItems) => sessions.when(
        loading: () => const ManagementLoading(),
        error: (error, _) => ManagementError(
          message: managementErrorMessage(error),
          onRetry: _reload,
        ),
        data: (sessionItems) =>
            _buildWorkspace(context, registrationItems, sessionItems),
      ),
    );
  }

  Future<void> _reload() async {
    ref.invalidate(managerRegistrationsProvider);
    ref.invalidate(managerSessionsProvider);
  }

  Widget _buildWorkspace(
    BuildContext context,
    List<ManagedRegistration> registrations,
    List<ClassSession> sessions,
  ) {
    final pending =
        registrations
            .where(
              (item) =>
                  _isSupportedRole(item) &&
                  item.status.toLowerCase() == 'pending',
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
    final query = _searchController.text.trim().toLowerCase();
    final visiblePending = pending
        .where(
          (item) =>
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.email.toLowerCase().contains(query) ||
              item.summary.toLowerCase().contains(query),
        )
        .toList(growable: false);
    final availableStudents = registrations
        .where(
          (item) => _isStudent(item) && item.status.toLowerCase() != 'declined',
        )
        .toList(growable: false);
    final availableTutors = registrations
        .where(
          (item) => _isTutor(item) && item.status.toLowerCase() != 'declined',
        )
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(managerRegistrationsProvider.future),
          ref.refresh(managerSessionsProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const ManagementPageHeader(
            title: 'Ghép lớp',
            subtitle:
                'Đối chiếu hồ sơ đang chờ và xem các buổi học đã được xếp lịch.',
          ),
          const SizedBox(height: 14),
          SegmentedButton<_MatchingView>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _MatchingView.pendingRequests,
                label: Text('Yêu cầu chờ'),
                icon: Icon(Icons.compare_arrows_rounded),
              ),
              ButtonSegment(
                value: _MatchingView.scheduledSessions,
                label: Text('Buổi đã xếp'),
                icon: Icon(Icons.event_available_outlined),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (value) => setState(() => _view = value.first),
          ),
          const SizedBox(height: 14),
          _MatchingScopeCard(view: _view),
          const SizedBox(height: 14),
          if (_view == _MatchingView.pendingRequests) ...[
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Tìm tên, email hoặc môn học',
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            if (pending.isEmpty)
              const SizedBox(
                height: 220,
                child: ManagementEmpty(
                  title: 'Không có yêu cầu chờ ghép',
                  message:
                      'Hồ sơ mới ở trạng thái chờ xử lý sẽ xuất hiện tại đây.',
                ),
              )
            else if (visiblePending.isEmpty)
              const SizedBox(
                height: 180,
                child: ManagementEmpty(
                  title: 'Không tìm thấy hồ sơ',
                  message: 'Thử tên, email hoặc môn học khác.',
                ),
              )
            else ...[
              Text(
                '${visiblePending.length} hồ sơ đang chờ',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final request in visiblePending) ...[
                _PendingRequestCard(
                  request: request,
                  candidates: _isStudent(request)
                      ? availableTutors
                            .where((candidate) => _matches(request, candidate))
                            .toList(growable: false)
                      : availableStudents
                            .where((candidate) => _matches(request, candidate))
                            .toList(growable: false),
                  candidateLabel: _isStudent(request) ? 'Tutor' : 'Sinh viên',
                ),
                const SizedBox(height: 10),
              ],
            ],
          ] else
            _ScheduledSessionsView(sessions: sessions),
        ],
      ),
    );
  }
}

class _MatchingScopeCard extends StatelessWidget {
  const _MatchingScopeCard({required this.view});

  final _MatchingView view;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPending = view == _MatchingView.pendingRequests;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isPending ? Icons.rule_folder_outlined : Icons.event_note_rounded,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isPending
                    ? 'Danh sách chỉ gồm hồ sơ đang chờ. Gợi ý đối chiếu dựa trên môn, ngôn ngữ, hình thức và địa điểm khi cần. Kết quả để tham khảo; ứng dụng không tự phân công hay lưu ghép lớp.'
                    : 'Các buổi dưới đây lấy từ lịch API theo khóa học. Đây là lịch đã tạo, không khẳng định mỗi buổi được sinh ra từ một kết quả ghép lớp.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.candidates,
    required this.candidateLabel,
  });

  final ManagedRegistration request;
  final List<ManagedRegistration> candidates;
  final String candidateLabel;

  @override
  Widget build(BuildContext context) {
    final isStudent = _isStudent(request);
    final colors = Theme.of(context).colorScheme;
    final detail = [
      if (request.subjects.isNotEmpty)
        'Môn: ${request.subjects.map((item) => item.name).join(', ')}',
      if (request.languages.isNotEmpty)
        'Ngôn ngữ: ${request.languages.map((item) => item.name).join(', ')}',
      if (request.sessionTypes.isNotEmpty)
        'Hình thức: ${request.sessionTypes.map((item) => item.name).join(', ')}',
      if (request.locations.isNotEmpty)
        'Địa điểm: ${request.locations.map((item) => item.name).join(', ')}',
    ].join('\n');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(isStudent ? Icons.school_outlined : Icons.person_outline),
        ),
        title: Text(
          request.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${isStudent ? 'Sinh viên' : 'Tutor'} · ${request.email}\n'
          '${candidates.length} $candidateLabel phù hợp tiêu chí',
        ),
        trailing: const ManagementStatus(status: 'Pending'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (detail.isNotEmpty)
            Align(alignment: Alignment.centerLeft, child: Text(detail)),
          const SizedBox(height: 10),
          if (candidates.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chưa có $candidateLabel nào khớp đủ thông tin.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else
            for (var index = 0; index < candidates.length; index++) ...[
              _CandidateTile(candidate: candidates[index]),
              if (index < candidates.length - 1) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate});

  final ManagedRegistration candidate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.person_outline_rounded, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      candidate.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ManagementStatus(status: candidate.status),
                ],
              ),
              const SizedBox(height: 3),
              Text(candidate.email),
              if (candidate.summary.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(candidate.summary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduledSessionsView extends StatelessWidget {
  const _ScheduledSessionsView({required this.sessions});

  final List<ClassSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox(
        height: 220,
        child: ManagementEmpty(
          title: 'Chưa có buổi học',
          message: 'Buổi học đã tạo sẽ xuất hiện theo từng khóa học.',
        ),
      );
    }

    final groups = <String, List<ClassSession>>{};
    for (final session in [
      ...sessions,
    ]..sort((a, b) => a.start.compareTo(b.start))) {
      groups.putIfAbsent(session.courseId, () => []).add(session);
    }
    final orderedGroups = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        for (final group in orderedGroups)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ExpansionTile(
              title: Text(
                group.value.first.courseTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${group.value.length} buổi học'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                for (final session in group.value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(session.title),
                    subtitle: Text(_sessionTimeLabel(context, session)),
                    trailing: ManagementStatus(status: session.status),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

String _sessionTimeLabel(BuildContext context, ClassSession session) {
  final localStart = session.start.toLocal();
  final localEnd = session.end.toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(localStart)} · '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localStart))}'
      '–${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localEnd))}';
}

bool _isSupportedRole(ManagedRegistration item) =>
    _isStudent(item) || _isTutor(item);

bool _isStudent(ManagedRegistration item) =>
    item.type.toLowerCase() == 'student';

bool _isTutor(ManagedRegistration item) =>
    const {'tutor', 'lecturer'}.contains(item.type.toLowerCase());

bool _matches(ManagedRegistration request, ManagedRegistration candidate) {
  if (!_overlaps(request.subjects, candidate.subjects)) return false;
  if (!_overlaps(request.languages, candidate.languages)) return false;
  if (!_overlaps(request.sessionTypes, candidate.sessionTypes)) return false;

  final needsLocation = request.sessionTypes.any(
    (option) => option.id.toLowerCase() != 'online',
  );
  if (needsLocation && !_overlaps(request.locations, candidate.locations)) {
    return false;
  }
  return true;
}

bool _overlaps(List<ManagementOption> first, List<ManagementOption> second) {
  final ids = first.map((item) => item.id.toLowerCase()).toSet();
  return second.any((item) => ids.contains(item.id.toLowerCase()));
}
