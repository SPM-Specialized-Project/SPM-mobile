import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_session.dart';
import '../../application/management_providers.dart';
import '../../data/management_models.dart';
import '../widgets/management_common.dart';

const _availableLanguages = <ManagementOption>[
  ManagementOption(id: 'vi', name: 'Tiếng Việt'),
  ManagementOption(id: 'en', name: 'English'),
  ManagementOption(id: 'cn', name: '简体中文'),
  ManagementOption(id: 'th', name: 'ภาษาไทย'),
];
const _availableTypes = <ManagementOption>[
  ManagementOption(id: 'online', name: 'Trực tuyến'),
  ManagementOption(id: 'hybrid', name: 'Kết hợp'),
];

class CourseRequestsScreen extends ConsumerWidget {
  const CourseRequestsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseRequestsProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(courseRequestsProvider),
      ),
      data: (requests) {
        final sorted = [...requests]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yêu cầu mở môn'),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(courseRequestsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                const ManagementPageHeader(
                  title: 'Yêu cầu khóa học',
                  subtitle:
                      'Coordinator/chairman có thể tạo và xử lý yêu cầu theo quyền từ backend.',
                ),
                if (sorted.isEmpty)
                  const SizedBox(
                    height: 240,
                    child: ManagementEmpty(
                      title: 'Chưa có yêu cầu',
                      message: 'Tạo yêu cầu mở môn đầu tiên.',
                    ),
                  )
                else
                  for (final request in sorted) ...[
                    _CourseRequestCard(
                      request: request,
                      onReview: () => _review(context, ref, request),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CourseRequestForm(session: session),
    );
    if (created == true) ref.invalidate(courseRequestsProvider);
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    CourseRequest request,
  ) async {
    final reason = TextEditingController(text: request.reasons);
    var status = request.status;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(request.courseName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Chờ xử lý')),
                  DropdownMenuItem(value: 'Approved', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Từ chối')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => status = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reason,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Ý kiến xử lý'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      try {
        await ref
            .read(managementRepositoryProvider)
            .reviewCourseRequest(
              id: request.id,
              status: status,
              reason: reason.text,
            );
        ref.invalidate(courseRequestsProvider);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
      }
    }
    reason.dispose();
  }
}

class _CourseRequestCard extends StatelessWidget {
  const _CourseRequestCard({required this.request, required this.onReview});

  final CourseRequest request;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) => Card(
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
                  request.courseName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ManagementStatus(status: request.status),
            ],
          ),
          const SizedBox(height: 5),
          Text('${request.courseCode} · ${request.coordinatorName}'),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.description),
          ],
          if (request.languages.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ngôn ngữ: ${request.languages.map((e) => e.name).join(', ')}',
            ),
          ],
          if (request.sessionTypes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Hình thức: ${request.sessionTypes.map((e) => e.name).join(', ')}',
            ),
          ],
          if (request.reasons.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text('Ý kiến: ${request.reasons}'),
          ],
          if (request.canEdit) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rule_rounded),
                label: const Text('Xử lý yêu cầu'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _CourseRequestForm extends ConsumerStatefulWidget {
  const _CourseRequestForm({required this.session});

  final AuthSession session;

  @override
  ConsumerState<_CourseRequestForm> createState() => _CourseRequestFormState();
}

class _CourseRequestFormState extends ConsumerState<_CourseRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  final Set<String> _languages = {'vi'};
  final Set<String> _types = {'online'};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _description.dispose();
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
                'Yêu cầu mở khóa học',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Người gửi: ${widget.session.user.name} · ${widget.session.user.email}',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên khóa học'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nhập tên khóa học.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Mã khóa học'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nhập mã khóa học.' : null,
              ),
              const SizedBox(height: 12),
              Text('Ngôn ngữ', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _availableLanguages)
                    FilterChip(
                      label: Text(option.name),
                      selected: _languages.contains(option.id),
                      onSelected: (selected) => setState(() {
                        selected
                            ? _languages.add(option.id)
                            : _languages.remove(option.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Hình thức', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _availableTypes)
                    FilterChip(
                      label: Text(option.name),
                      selected: _types.contains(option.id),
                      onSelected: (selected) => setState(() {
                        selected
                            ? _types.add(option.id)
                            : _types.remove(option.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                maxLength: 800,
                decoration: const InputDecoration(
                  labelText: 'Mô tả và mục tiêu môn học',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().length < 10
                    ? 'Mô tả ít nhất 10 ký tự.'
                    : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_languages.isEmpty || _types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn ít nhất một ngôn ngữ và hình thức.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(managementRepositoryProvider)
          .createCourseRequest(
            session: widget.session,
            courseName: _name.text,
            courseCode: _code.text,
            description: _description.text,
            languages: [
              for (final option in _availableLanguages)
                if (_languages.contains(option.id)) option,
            ],
            sessionTypes: [
              for (final option in _availableTypes)
                if (_types.contains(option.id)) option,
            ],
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
    }
  }
}
