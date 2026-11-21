import 'package:flutter/material.dart';

import '../../auth/data/auth_session.dart';
import '../data/local_communication_store.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.ownerId, required this.role, super.key});

  final String ownerId;
  final UserRole role;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _memberExamples = [
    'Nguyễn Văn A',
    'Trần Thị B',
    'Lê Văn C',
    'Phạm Thị D',
    'Hoàng Văn E',
  ];

  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _conversations = const [];
  String? _selectedId;
  String _query = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await LocalCommunicationStore.loadConversations(
      widget.ownerId,
    );
    if (mounted) {
      setState(() {
        _conversations = items;
        _loading = false;
      });
    }
  }

  Future<void> _persist() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await LocalCommunicationStore.saveConversations(
        widget.ownerId,
        _conversations,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu nội dung trên thiết bị.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic>? get _selectedConversation {
    for (final conversation in _conversations) {
      if (conversation['id'] == _selectedId) return conversation;
    }
    return null;
  }

  List<Map<String, dynamic>> _messagesOf(Map<String, dynamic> conversation) {
    final messages = conversation['messages'];
    if (messages is! List) return const [];
    return [
      for (final message in messages)
        if (message is Map) Map<String, dynamic>.from(message),
    ];
  }

  Future<void> _sendMessage() async {
    final conversation = _selectedConversation;
    final text = _messageController.text.trim();
    if (conversation == null || text.isEmpty || _saving) return;
    final message = {
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'sender': 'Bạn',
      'text': text,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'isLocalDraft': true,
    };
    final updated = {
      ...conversation,
      'isExample': false,
      'messages': [..._messagesOf(conversation), message],
    };
    _replaceConversation(updated);
    _messageController.clear();
    await _persist();
  }

  void _replaceConversation(Map<String, dynamic> updated) {
    setState(() {
      final index = _conversations.indexWhere(
        (item) => item['id'] == updated['id'],
      );
      if (index < 0) {
        _conversations = [..._conversations, updated];
      } else {
        final copy = [..._conversations];
        copy[index] = updated;
        _conversations = copy;
      }
    });
  }

  Future<void> _createGroup() async {
    final result = await _editGroup();
    if (result == null) return;
    final now = DateTime.now().toUtc();
    final group = {
      'id': 'local-group-${now.microsecondsSinceEpoch}',
      'title': result['title'],
      'description':
          '${(result['members'] as List).length} thành viên · cục bộ',
      'isGroup': true,
      'isExample': false,
      'members': result['members'],
      'messages': <Map<String, dynamic>>[],
      'createdAt': now.toIso8601String(),
    };
    setState(() {
      _conversations = [..._conversations, group];
      _selectedId = group['id'] as String;
    });
    await _persist();
  }

  Future<Map<String, dynamic>?> _editGroup({
    Map<String, dynamic>? existing,
  }) async {
    final nameController = TextEditingController(
      text: existing?['title'] as String? ?? '',
    );
    final currentMembers = Set<String>.from(
      (existing?['members'] as List? ?? const []).whereType<String>(),
    );
    final formKey = GlobalKey<FormState>();
    var selectedMembers = currentMembers;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: Text(existing == null ? 'Tạo nhóm cục bộ' : 'Quản lý nhóm'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      maxLength: 80,
                      decoration: const InputDecoration(labelText: 'Tên nhóm'),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Nhập tên nhóm.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thành viên minh họa',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final member in _memberExamples)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(member),
                        value: selectedMembers.contains(member),
                        onChanged: (selected) => updateDialog(() {
                          selectedMembers = {...selectedMembers};
                          if (selected == true) {
                            selectedMembers.add(member);
                          } else {
                            selectedMembers.remove(member);
                          }
                        }),
                      ),
                    if (selectedMembers.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn ít nhất một thành viên.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
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
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate() ||
                    selectedMembers.isEmpty) {
                  return;
                }
                Navigator.pop(context, {
                  'title': nameController.text.trim(),
                  'members': selectedMembers.toList()..sort(),
                });
              },
              child: Text(existing == null ? 'Tạo nhóm' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    return result;
  }

  Future<void> _manageSelectedGroup(String action) async {
    final conversation = _selectedConversation;
    if (conversation == null || conversation['isGroup'] != true) return;
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa nhóm trên thiết bị?'),
          content: const Text(
            'Nhóm này chưa được gửi hoặc đồng bộ với ai khác.',
          ),
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
      setState(() {
        _conversations = _conversations
            .where((item) => item['id'] != conversation['id'])
            .toList();
        _selectedId = null;
      });
      await _persist();
      return;
    }

    final result = await _editGroup(existing: conversation);
    if (result == null) return;
    _replaceConversation({
      ...conversation,
      'title': result['title'],
      'members': result['members'],
      'description':
          '${(result['members'] as List).length} thành viên · cục bộ',
      'isExample': false,
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedConversation;
    final colors = Theme.of(context).colorScheme;
    final filtered = _conversations
        .where((conversation) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              (conversation['title'] as String? ?? '').toLowerCase().contains(
                query,
              ) ||
              (conversation['description'] as String? ?? '')
                  .toLowerCase()
                  .contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: selected == null
            ? null
            : IconButton(
                tooltip: 'Quay lại danh sách',
                onPressed: () => setState(() => _selectedId = null),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(selected?['title'] as String? ?? 'Tin nhắn'),
        actions: [
          if (selected?['isGroup'] == true && widget.role == UserRole.lecturer)
            PopupMenuButton<String>(
              tooltip: 'Quản lý nhóm',
              onSelected: _manageSelectedGroup,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Sửa tên và thành viên'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Xóa nhóm cục bộ')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : selected == null
            ? _conversationList(filtered, colors)
            : _conversationView(selected, colors),
      ),
      floatingActionButton:
          !_loading && selected == null && widget.role == UserRole.lecturer
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _createGroup,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Tạo nhóm'),
            )
          : null,
    );
  }

  Widget _conversationList(
    List<Map<String, dynamic>> conversations,
    ColorScheme colors,
  ) => Column(
    children: [
      _PreviewBanner(
        text:
            'Hội thoại và tên người trong danh sách là dữ liệu minh họa từ web. Tin bạn soạn chỉ lưu trên thiết bị, không gửi cho người thật.',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SearchBar(
          controller: _searchController,
          hintText: 'Tìm cuộc trò chuyện',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (_query.isNotEmpty)
              IconButton(
                tooltip: 'Xóa tìm kiếm',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
          ],
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      Expanded(
        child: conversations.isEmpty
            ? Center(
                child: Text(
                  'Không tìm thấy cuộc trò chuyện.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            : ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final messages = _messagesOf(conversation);
                  final last = messages.lastOrNull;
                  final isGroup = conversation['isGroup'] == true;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Icon(
                        isGroup
                            ? Icons.groups_2_outlined
                            : Icons.school_outlined,
                      ),
                    ),
                    title: Text(
                      conversation['title'] as String? ?? 'Cuộc trò chuyện',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      last?['text'] as String? ??
                          conversation['description'] as String? ??
                          'Chưa có nội dung',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => setState(
                      () => _selectedId = conversation['id'] as String?,
                    ),
                  );
                },
              ),
      ),
    ],
  );

  Widget _conversationView(
    Map<String, dynamic> conversation,
    ColorScheme colors,
  ) {
    final messages = _messagesOf(conversation);
    final members = conversation['members'] as List? ?? const [];
    return Column(
      children: [
        _PreviewBanner(
          text:
              'Đây là bản xem trước cục bộ. Tin nhắn không được gửi hoặc đồng bộ với thành viên khác.',
        ),
        if (conversation['isGroup'] == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${members.length} thành viên · danh sách minh họa',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      'Chưa có tin nhắn. Nội dung bạn soạn sẽ chỉ lưu trên thiết bị.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _MessageBubble(
                    message: messages[index],
                    isMine: messages[index]['sender'] == 'Bạn',
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Soạn bản nháp cục bộ',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: IconButton.filled(
                    tooltip: 'Lưu bản nháp trên thiết bị',
                    onPressed: _saving ? null : _sendMessage,
                    icon: const Icon(Icons.save_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Map<String, dynamic> message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isExample = message['isExample'] == true;
    final time = DateTime.tryParse(message['timestamp'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMine
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Text(
                      message['sender'] as String? ?? 'Thành viên minh họa',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(message['text'] as String? ?? ''),
                  const SizedBox(height: 4),
                  Text(
                    isExample
                        ? 'Mẫu giao diện'
                        : time == null
                        ? 'Bản nháp trên thiết bị'
                        : 'Bản nháp · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time.toLocal()))}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isMine
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
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
              text,
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
