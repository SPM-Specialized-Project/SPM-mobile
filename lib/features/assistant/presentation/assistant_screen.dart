import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_session.dart';
import '../application/assistant_providers.dart';
import '../data/assistant_knowledge.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({
    required this.role,
    required this.onOpenDestination,
    super.key,
  });

  final UserRole role;
  final ValueChanged<AssistantDestination> onOpenDestination;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final _turns = <_AssistantTurn>[];
  bool _sending = false;

  String get _knowledgeRole =>
      widget.role == UserRole.lecturer ? 'tutor' : 'student';

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedQuestion]) async {
    final question = (suggestedQuestion ?? _questionController.text).trim();
    if (question.isEmpty || _sending) return;

    _questionController.clear();
    final turn = _AssistantTurn(question);
    setState(() {
      _turns.add(turn);
      _sending = true;
    });
    _scrollToEnd();

    try {
      final knowledge = await ref.read(assistantKnowledgeProvider.future);
      AssistantReply reply;
      try {
        reply = await ref.read(assistantRepositoryProvider).answer(question);
      } catch (_) {
        final localReply = knowledge.answer(question, _knowledgeRole);
        reply = AssistantReply(
          status: localReply.status,
          answer: localReply.answer,
          sources: localReply.sources,
          title: localReply.title,
          note: [
            localReply.note,
            'Backend trợ lý chưa sẵn sàng; nội dung được tra cứu cục bộ, chưa sinh bằng model.',
          ].whereType<String>().join(' '),
          featureStatus: localReply.featureStatus,
          mode: 'local-retrieval',
          destination: localReply.destination,
        );
      }
      if (!mounted) return;
      setState(() => turn.reply = reply);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _turns.remove(turn);
        _questionController.text = question;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa thể tra cứu hướng dẫn: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeState = ref.watch(assistantKnowledgeProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý hướng dẫn'),
        actions: [
          IconButton(
            tooltip: 'Xóa hội thoại',
            onPressed: _turns.isEmpty || _sending
                ? null
                : () => setState(_turns.clear),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trợ lý tra cứu tài liệu theo vai trò. Khi backend hoặc model chưa sẵn sàng, ứng dụng dùng kho tri thức cục bộ. Trợ lý không đọc lịch cá nhân hoặc thực hiện thao tác thay bạn.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: knowledgeState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 40),
                        const SizedBox(height: 12),
                        const Text('Chưa tải được kho hướng dẫn.'),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              ref.invalidate(assistantKnowledgeProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (_) => _conversation(context),
              ),
            ),
            _composer(context),
          ],
        ),
      ),
    );
  }

  Widget _conversation(BuildContext context) {
    if (_turns.isEmpty) {
      final prompts = widget.role == UserRole.lecturer
          ? const ['Cách tạo buổi học?', 'Cách xem bài nộp?', 'Cách điểm danh?']
          : const [
              'Cách xem lịch học?',
              'Cách đăng ký lớp?',
              'Tìm tài liệu lớp ở đâu?',
            ];
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 38,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn cần hướng dẫn thao tác nào?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn câu hỏi gợi ý hoặc nhập câu hỏi. Trợ lý sẽ báo rõ khi hướng dẫn chỉ thuộc đặc tả hoặc chưa được xác nhận trên app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          for (final prompt in prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActionChip(
                avatar: const Icon(Icons.arrow_outward_rounded, size: 16),
                label: Text(prompt),
                onPressed: _sending ? null : () => _send(prompt),
              ),
            ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _turns.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _turns.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _TurnView(
          turn: _turns[index],
          onOpenDestination: widget.onOpenDestination,
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final enabled = !_sending && ref.watch(assistantKnowledgeProvider).hasValue;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                enabled: enabled,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton.filled(
                tooltip: 'Gửi câu hỏi',
                onPressed: enabled ? _send : null,
                icon: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantTurn {
  _AssistantTurn(this.question);

  final String question;
  AssistantReply? reply;
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.onOpenDestination});

  final _AssistantTurn turn;
  final ValueChanged<AssistantDestination> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                turn.question,
                style: TextStyle(color: colors.onPrimary),
              ),
            ),
          ),
          if (turn.reply case final reply?) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reply.title != null) ...[
                      Text(
                        reply.title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (reply.featureStatus != null) ...[
                      _StatusLabel(status: reply.featureStatus!),
                      const SizedBox(height: 8),
                    ],
                    if (reply.mode != null) ...[
                      _AssistantModeLabel(mode: reply.mode!),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(reply.answer),
                    if (reply.destination != null &&
                        reply.featureStatus == 'design') ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => onOpenDestination(reply.destination!),
                        icon: Icon(reply.destination!.icon),
                        label: Text(reply.destination!.label),
                      ),
                    ],
                    if (reply.note != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        reply.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    for (final citation in reply.sources) ...[
                      const SizedBox(height: 12),
                      Divider(color: colors.outlineVariant),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nguồn ${citation.id}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  citation.section,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                SelectableText(
                                  citation.url,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantModeLabel extends StatelessWidget {
  const _AssistantModeLabel({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, icon) = switch (mode) {
      'rag' => ('RAG · đã diễn đạt từ nguồn', Icons.auto_awesome_outlined),
      'retrieval' => ('Tra cứu nguồn', Icons.menu_book_outlined),
      _ => ('Tra cứu tại thiết bị', Icons.phone_android_outlined),
    };
    return Chip(
      avatar: Icon(icon, size: 17, color: colors.onTertiaryContainer),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.tertiaryContainer,
      side: BorderSide.none,
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, icon) = switch (status) {
      'design' => ('Theo thiết kế', Icons.description_outlined),
      'proposed' => ('Đề xuất, chưa xác nhận', Icons.lightbulb_outline_rounded),
      _ => ('Cần xác nhận', Icons.fact_check_outlined),
    };
    return Chip(
      avatar: Icon(icon, size: 17, color: colors.onSecondaryContainer),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.secondaryContainer,
      side: BorderSide.none,
    );
  }
}
