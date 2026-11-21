import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/session_request.dart';
import '../../application/management_providers.dart';
import 'session_request_schedule_dialog.dart';
import '../widgets/management_common.dart';

class SessionRequestsScreen extends ConsumerStatefulWidget {
  const SessionRequestsScreen({super.key});

  @override
  ConsumerState<SessionRequestsScreen> createState() =>
      _SessionRequestsScreenState();
}

class _SessionRequestsScreenState extends ConsumerState<SessionRequestsScreen> {
  final _searchController = TextEditingController();
  bool _pendingOnly = true;
  String? _workingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managerSessionRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu buổi học')),
      body: state.when(
        loading: () => const ManagementLoading(),
        error: (error, _) => ManagementError(
          message: managementErrorMessage(error),
          onRetry: () => ref.invalidate(managerSessionRequestsProvider),
        ),
        data: (items) => _buildList(context, items),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SessionRequest> items) {
    final query = _searchController.text.trim().toLowerCase();
    final visible =
        items
            .where((item) {
              if (_pendingOnly &&
                  !{'pending', 'scheduling'}.contains(item.status)) {
                return false;
              }
              if (query.isEmpty) return true;
              return item.title.toLowerCase().contains(query) ||
                  item.courseTitle.toLowerCase().contains(query) ||
                  item.requesterEmail.toLowerCase().contains(query);
            })
            .toList(growable: false)
          ..sort(
            (left, right) => (right.createdAt ?? DateTime(0)).compareTo(
              left.createdAt ?? DateTime(0),
            ),
          );
    final pendingCount = items
        .where((item) => {'pending', 'scheduling'}.contains(item.status))
        .length;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(managerSessionRequestsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          ManagementPageHeader(
            title: 'Yêu cầu từ sinh viên',
            subtitle: pendingCount == 0
                ? 'Không có yêu cầu mới cần xử lý.'
                : '$pendingCount yêu cầu đang chờ xử lý.',
          ),
          const _RequestWorkflowNotice(),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm môn học, tiêu đề hoặc email',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
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
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Đang chờ')),
              ButtonSegment(value: false, label: Text('Tất cả')),
            ],
            selected: {_pendingOnly},
            onSelectionChanged: (selection) =>
                setState(() => _pendingOnly = selection.first),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            SizedBox(
              height: 220,
              child: ManagementEmpty(
                title: items.isEmpty
                    ? 'Chưa có yêu cầu'
                    : 'Không tìm thấy yêu cầu',
                message: items.isEmpty
                    ? 'Yêu cầu sinh viên gửi lên sẽ xuất hiện tại đây.'
                    : 'Đổi bộ lọc hoặc từ khóa để xem yêu cầu khác.',
              ),
            )
          else
            for (final request in visible) ...[
              _SessionRequestReviewCard(
                request: request,
                busy: _workingId == request.id,
                onSchedule: () => _schedule(request),
                onConfirmAbsence: () => _review(request, 'approved'),
                onDecline: () => _decline(request),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _decline(SessionRequest request) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Lý do phản hồi',
            hintText: 'Cho sinh viên biết vì sao yêu cầu chưa phù hợp.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(context, value);
            },
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    await _review(request, 'declined', reason: reason);
  }

  Future<void> _review(
    SessionRequest request,
    String status, {
    String reason = '',
  }) async {
    if (_workingId != null) return;
    setState(() => _workingId = request.id);
    try {
      await ref
          .read(managementRepositoryProvider)
          .reviewSessionRequest(id: request.id, status: status, reason: reason);
      ref.invalidate(managerSessionRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Đã xác nhận yêu cầu xin vắng.'
                  : 'Đã gửi phản hồi từ chối.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _schedule(SessionRequest request) async {
    if (_workingId != null) return;
    final draft = await showSessionRequestScheduleDialog(context, request);
    if (draft == null || !mounted) return;
    setState(() => _workingId = request.id);
    try {
      await ref
          .read(managementRepositoryProvider)
          .scheduleSessionRequest(
            id: request.id,
            title: draft.title,
            description: draft.description,
            start: draft.start,
            end: draft.end,
            method: draft.method,
            link: draft.link,
            location: draft.location,
          );
      ref.invalidate(managerSessionRequestsProvider);
      ref.invalidate(managerSessionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo buổi học và thêm vào lịch điều phối.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }
}

class _RequestWorkflowNotice extends StatelessWidget {
  const _RequestWorkflowNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Với buổi mới hoặc học bù, chọn “Tạo lịch” để chốt giờ, hình thức và địa điểm; lịch được thêm ngay vào lịch điều phối. Yêu cầu xin vắng chỉ được xác nhận, không tạo buổi học.',
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _SessionRequestReviewCard extends StatelessWidget {
  const _SessionRequestReviewCard({
    required this.request,
    required this.busy,
    required this.onSchedule,
    required this.onConfirmAbsence,
    required this.onDecline,
  });

  final SessionRequest request;
  final bool busy;
  final VoidCallback onSchedule;
  final VoidCallback onConfirmAbsence;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final proposedAt = request.proposedAt.toLocal();
    final typeLabel = switch (request.requestType) {
      'makeup' => 'Học bù',
      'absent' => 'Xin vắng',
      _ => 'Buổi mới',
    };
    return Card(
      margin: EdgeInsets.zero,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ManagementStatus(status: request.status),
              ],
            ),
            const SizedBox(height: 5),
            Text('${request.courseTitle} · $typeLabel'),
            const SizedBox(height: 3),
            Text('Người gửi: ${request.requesterEmail}'),
            const SizedBox(height: 3),
            Text(
              'Đề xuất ${localizations.formatMediumDate(proposedAt)} · '
              '${TimeOfDay.fromDateTime(proposedAt).format(context)}',
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(request.description),
            ],
            if (request.reviewReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Phản hồi: ${request.reviewReason}'),
            ],
            if (request.reviewedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Đã xử lý${request.reviewedBy == null ? '' : ' bởi ${request.reviewedBy}'} · '
                '${localizations.formatMediumDate(request.reviewedAt!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (request.scheduledSessionId != null) ...[
              const SizedBox(height: 6),
              if (request.scheduledStart != null) ...[
                Text(
                  'Đã xếp lịch: ${localizations.formatMediumDate(request.scheduledStart!.toLocal())} · '
                  '${TimeOfDay.fromDateTime(request.scheduledStart!.toLocal()).format(context)}'
                  '${request.scheduledEnd == null ? '' : '–${TimeOfDay.fromDateTime(request.scheduledEnd!.toLocal()).format(context)}'}',
                ),
              ],
              Text('Mã buổi học: ${request.scheduledSessionId}'),
            ],
            if (request.status == 'pending' ||
                request.status == 'scheduling') ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.status == 'pending')
                    OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: const Text('Từ chối'),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : request.requestType == 'absent'
                        ? onConfirmAbsence
                        : onSchedule,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            request.requestType == 'absent'
                                ? 'Xác nhận xin vắng'
                                : request.status == 'scheduling'
                                ? 'Thử tạo lịch lại'
                                : 'Tạo lịch buổi học',
                          ),
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
