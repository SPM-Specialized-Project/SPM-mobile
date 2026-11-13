import 'package:flutter/material.dart';

import '../data/local_communication_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.ownerId, super.key});

  final String ownerId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _unreadOnly = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalCommunicationStore.loadNotifications(
      widget.ownerId,
    );
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _persist() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await LocalCommunicationStore.saveNotifications(widget.ownerId, _items);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu thay đổi trên thiết bị.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final index = _items.indexWhere(
      (candidate) => candidate['id'] == item['id'],
    );
    if (index < 0 || item['isRead'] == true) return;
    setState(() => _items[index] = {..._items[index], 'isRead': true});
    await _persist();
  }

  Future<void> _markAllRead() async {
    setState(
      () => _items = [
        for (final item in _items) {...item, 'isRead': true},
      ],
    );
    await _persist();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa các thông báo trên thiết bị?'),
        content: const Text('Thao tác này chỉ xóa bản minh họa cục bộ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _items = []);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((item) => item['isRead'] != true).length;
    final visibleItems = _items
        .where((item) => !_unreadOnly || item['isRead'] != true)
        .toList(growable: false);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: _saving ? null : _markAllRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
          if (_items.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn thông báo',
              onSelected: (value) {
                if (value == 'clear') _clearAll();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear', child: Text('Xóa bản minh họa')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _PreviewNotice(
                    message:
                        'Dữ liệu minh họa theo giao diện web. Không phải thông báo thật và không đồng bộ với backend.',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Tất cả'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Chưa đọc'),
                              ),
                            ],
                            selected: {_unreadOnly},
                            onSelectionChanged: (selection) =>
                                setState(() => _unreadOnly = selection.first),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          label: '$unreadCount thông báo chưa đọc',
                          child: Text('$unreadCount'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibleItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 42,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _items.isEmpty
                                        ? 'Chưa có thông báo'
                                        : 'Không còn thông báo chưa đọc',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _items.isEmpty
                                        ? 'Thông báo thật sẽ hiển thị khi backend có dịch vụ event/inbox.'
                                        : 'Bạn đã đọc hết các thông báo minh họa.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: visibleItems.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              final read = item['isRead'] == true;
                              final title =
                                  item['title'] as String? ?? 'Thông báo';
                              final message = item['message'] as String? ?? '';
                              final time = DateTime.tryParse(
                                item['timestamp'] as String? ?? '',
                              );
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: read
                                      ? colors.surfaceContainerHighest
                                      : colors.primaryContainer,
                                  foregroundColor: read
                                      ? colors.onSurfaceVariant
                                      : colors.onPrimaryContainer,
                                  child: Icon(
                                    _iconFor(item['type'] as String?),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: read
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(message),
                                      const SizedBox(height: 5),
                                      Text(
                                        time == null
                                            ? 'Thời điểm chưa có'
                                            : _relativeTime(time),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () => _markRead(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _iconFor(String? type) => switch (type) {
    'success' => Icons.check_circle_outline_rounded,
    'warning' => Icons.warning_amber_rounded,
    'error' => Icons.error_outline_rounded,
    _ => Icons.notifications_outlined,
  };

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time.toLocal());
    if (difference.inMinutes < 1) {
      return 'Vừa xong · minh họa';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước · minh họa';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước · minh họa';
    }
    return MaterialLocalizations.of(context).formatMediumDate(time.toLocal());
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onTertiaryContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
