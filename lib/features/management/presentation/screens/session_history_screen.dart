import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/domain/class_session.dart';
import '../../../learning/domain/session_request.dart';
import '../../application/management_providers.dart';
import '../widgets/management_common.dart';

enum _HistoryFilter { past, cancelled, all }

class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  final _search = TextEditingController();
  _HistoryFilter _filter = _HistoryFilter.past;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managerSessionsProvider);
    final requestState = ref.watch(managerSessionRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử buổi học')),
      body: state.when(
        loading: () => const ManagementLoading(),
        error: (error, _) => ManagementError(
          message: managementErrorMessage(error),
          onRetry: () => ref.invalidate(managerSessionsProvider),
        ),
        data: (sessions) {
          final now = DateTime.now();
          final normalized = _query.trim().toLowerCase();
          final sorted = sessions.where((item) {
            final matchesStatus = switch (_filter) {
              _HistoryFilter.past =>
                item.end.isBefore(now) &&
                    item.status.toLowerCase() != 'cancelled',
              _HistoryFilter.cancelled =>
                item.status.toLowerCase() == 'cancelled',
              _HistoryFilter.all => true,
            };
            final matchesQuery =
                normalized.isEmpty ||
                item.title.toLowerCase().contains(normalized) ||
                item.courseTitle.toLowerCase().contains(normalized);
            return matchesStatus && matchesQuery;
          }).toList()..sort((a, b) => b.start.compareTo(a.start));

          return RefreshIndicator(
            onRefresh: () async {
              try {
                await Future.wait([
                  ref.refresh(managerSessionsProvider.future),
                  ref.refresh(managerSessionRequestsProvider.future),
                ]);
              } catch (_) {
                // Provider states below show per-resource errors independently.
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                const ManagementPageHeader(
                  title: 'Buổi học từ máy chủ',
                  subtitle:
                      'Xem lại các buổi đã lưu trong lịch theo quyền tài khoản.',
                ),
                const _HistoryScopeCard(),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo môn hoặc tên buổi',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<_HistoryFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _HistoryFilter.past,
                      label: Text('Đã diễn ra'),
                    ),
                    ButtonSegment(
                      value: _HistoryFilter.cancelled,
                      label: Text('Đã hủy'),
                    ),
                    ButtonSegment(
                      value: _HistoryFilter.all,
                      label: Text('Tất cả'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) =>
                      setState(() => _filter = selection.first),
                ),
                const SizedBox(height: 14),
                if (sorted.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: ManagementEmpty(
                      title: 'Chưa có buổi phù hợp',
                      message:
                          'Thử bộ lọc khác hoặc tải lại lịch buổi học đã lưu.',
                    ),
                  )
                else
                  for (final session in sorted) ...[
                    _HistorySessionCard(
                      session: session,
                      onTap: () => _showDetails(context, session),
                    ),
                    const SizedBox(height: 9),
                  ],
                const SizedBox(height: 24),
                Text(
                  'Yêu cầu buổi học',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yêu cầu được giới hạn theo tài khoản và khóa học bạn có quyền xem.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                requestState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _RequestHistoryError(
                    message: managementErrorMessage(error),
                    onRetry: () =>
                        ref.invalidate(managerSessionRequestsProvider),
                  ),
                  data: (requests) => _RequestHistoryList(requests: requests),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, ClassSession session) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _HistorySessionDetails(session: session),
      );
}

class _HistoryScopeCard extends StatelessWidget {
  const _HistoryScopeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buổi học và yêu cầu được tải riêng. Trạng thái yêu cầu đến từ API /session-requests; bản nháp trên thiết bị không nằm trong danh sách này.',
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestHistoryError extends StatelessWidget {
  const _RequestHistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: colors.onErrorContainer)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestHistoryList extends StatelessWidget {
  const _RequestHistoryList({required this.requests});

  final List<SessionRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chưa có yêu cầu buổi học.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final sorted = [...requests]
      ..sort(
        (left, right) => (right.createdAt ?? DateTime(0)).compareTo(
          left.createdAt ?? DateTime(0),
        ),
      );
    return Column(
      children: [
        for (final request in sorted) ...[
          _HistoryRequestCard(
            request: request,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _HistoryRequestDetails(request: request),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HistoryRequestCard extends StatelessWidget {
  const _HistoryRequestCard({required this.request, required this.onTap});

  final SessionRequest request;
  final VoidCallback onTap;

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
      child: ListTile(
        onTap: onTap,
        title: Text(
          request.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${request.courseTitle} · $typeLabel\n'
          '${localizations.formatMediumDate(proposedAt)} · '
          '${TimeOfDay.fromDateTime(proposedAt).format(context)}',
        ),
        isThreeLine: true,
        trailing: ManagementStatus(status: request.status),
      ),
    );
  }
}

class _HistoryRequestDetails extends StatelessWidget {
  const _HistoryRequestDetails({required this.request});

  final SessionRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final proposedAt = request.proposedAt.toLocal();
    final typeLabel = switch (request.requestType) {
      'makeup' => 'Học bù',
      'absent' => 'Xin vắng',
      _ => 'Buổi mới',
    };
    return Padding(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${localizations.formatMediumDate(proposedAt)} · '
                  '${TimeOfDay.fromDateTime(proposedAt).format(context)}',
                ),
              ),
              ManagementStatus(status: request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('Loại yêu cầu: $typeLabel'),
          Text('Người gửi: ${request.requesterEmail}'),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(request.description),
          ],
          if (request.reviewReason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Phản hồi: ${request.reviewReason}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({required this.session, required this.onTap});

  final ClassSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = session.start.toLocal();
    final end = session.end.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Icon(
            session.status.toLowerCase() == 'cancelled'
                ? Icons.event_busy_outlined
                : Icons.event_available_outlined,
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${session.courseTitle}\n${localizations.formatMediumDate(start)} · ${TimeOfDay.fromDateTime(start).format(context)}–${TimeOfDay.fromDateTime(end).format(context)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _HistorySessionDetails extends StatelessWidget {
  const _HistorySessionDetails({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final start = session.start.toLocal();
    final end = session.end.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            session.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(session.courseTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${localizations.formatMediumDate(start)} · ${TimeOfDay.fromDateTime(start).format(context)}–${TimeOfDay.fromDateTime(end).format(context)}',
                ),
              ),
              ManagementStatus(status: session.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.method.toLowerCase() == 'online'
                ? 'Trực tuyến'
                : (session.location ?? 'Trực tiếp'),
          ),
          if (session.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(session.description),
          ],
          if (session.link?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text('Liên kết'),
            SelectableText(session.link!),
          ],
        ],
      ),
    );
  }
}
