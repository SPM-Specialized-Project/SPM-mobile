import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../management/presentation/widgets/management_common.dart';
import '../../application/admin_providers.dart';
import '../../data/codepulse_models.dart';

class AdminCodePulseScreen extends StatelessWidget {
  const AdminCodePulseScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TabBar(
        tabs: [
          Tab(text: 'Học kỳ'),
          Tab(text: 'Lớp DSA'),
        ],
      ),
      body: const TabBarView(children: [_TermsTab(), _ClassroomsTab()]),
    ),
  );
}

class _TermsTab extends ConsumerWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(codePulseTermsProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(codePulseTermsProvider),
      ),
      data: (terms) => RefreshIndicator(
        onRefresh: () => ref.refresh(codePulseTermsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const ManagementPageHeader(
              title: 'Quản lý học kỳ CodePulse',
              subtitle:
                  'Backend cho admin xem và quản lý term của khóa DSA (course 13).',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _editTerm(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo học kỳ'),
              ),
            ),
            const SizedBox(height: 12),
            if (terms.isEmpty)
              const SizedBox(
                height: 220,
                child: ManagementEmpty(
                  title: 'Chưa có học kỳ',
                  message: 'Tạo học kỳ trước khi mở lớp DSA.',
                ),
              )
            else
              for (final term in terms) ...[
                _TermCard(
                  term: term,
                  onEdit: () => _editTerm(context, ref, term),
                  onDelete: () => _deleteTerm(context, ref, term),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

Future<void> _editTerm(
  BuildContext context,
  WidgetRef ref, [
  CodePulseTerm? term,
]) async {
  final values = await showDialog<Map<String, Object?>>(
    context: context,
    builder: (_) => _TermDialog(term: term),
  );
  if (values == null) return;
  try {
    final repository = ref.read(codePulseRepositoryProvider);
    if (term == null) {
      await repository.createTerm(
        name: values['name']! as String,
        startDate: values['startDate']! as DateTime,
        endDate: values['endDate']! as DateTime,
        resetDate: values['resetDate']! as DateTime,
      );
    } else {
      await repository.updateTerm(term.id, {
        'name': values['name'],
        'startDate': _dateOnly(values['startDate']! as DateTime),
        'endDate': _dateOnly(values['endDate']! as DateTime),
        'resetDate': _dateOnly(values['resetDate']! as DateTime),
        'status': values['status'],
      });
    }
    ref.invalidate(codePulseTermsProvider);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
  }
}

Future<void> _deleteTerm(
  BuildContext context,
  WidgetRef ref,
  CodePulseTerm term,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa học kỳ?'),
      content: Text(
        'Xóa "${term.name}". Backend sẽ từ chối nếu vẫn còn lớp dùng học kỳ này.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(codePulseRepositoryProvider).deleteTerm(term.id);
    ref.invalidate(codePulseTermsProvider);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.onEdit,
    required this.onDelete,
  });

  final CodePulseTerm term;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  term.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ManagementStatus(status: term.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_date(term.startDate)} – ${_date(term.endDate)}'),
          Text('Ngày reset: ${_date(term.resetDate)}'),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TermDialog extends StatefulWidget {
  const _TermDialog({this.term});

  final CodePulseTerm? term;

  @override
  State<_TermDialog> createState() => _TermDialogState();
}

class _TermDialogState extends State<_TermDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.term?.name ?? '');
  late DateTime _start = widget.term?.startDate ?? DateTime.now();
  late DateTime _end =
      widget.term?.endDate ?? DateTime.now().add(const Duration(days: 180));
  late DateTime _reset =
      widget.term?.resetDate ?? DateTime.now().add(const Duration(days: 181));
  late String _status = widget.term?.status ?? 'DRAFT';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.term == null ? 'Tạo học kỳ' : 'Sửa học kỳ'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên học kỳ'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nhập tên.' : null,
            ),
            const SizedBox(height: 10),
            _DateButton(
              label: 'Bắt đầu',
              value: _start,
              onChanged: (value) => setState(() => _start = value),
            ),
            _DateButton(
              label: 'Kết thúc',
              value: _end,
              onChanged: (value) => setState(() => _end = value),
            ),
            _DateButton(
              label: 'Ngày reset',
              value: _reset,
              onChanged: (value) => setState(() => _reset = value),
            ),
            if (widget.term != null)
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Bản nháp')),
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Text('Đang hoạt động'),
                  ),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('Lưu trữ')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu')),
    ],
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu.')),
      );
      return;
    }
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'startDate': _start,
      'endDate': _end,
      'resetDate': _reset,
      'status': _status,
    });
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(_date(value)),
    trailing: const Icon(Icons.calendar_month_outlined),
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
      );
      if (selected != null) onChanged(selected);
    },
  );
}

class _ClassroomsTab extends ConsumerWidget {
  const _ClassroomsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomsState = ref.watch(codePulseClassroomsProvider);
    final termsState = ref.watch(codePulseTermsProvider);
    return classroomsState.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(codePulseClassroomsProvider),
      ),
      data: (classrooms) => termsState.when(
        loading: () => const ManagementLoading(),
        error: (error, _) => ManagementError(
          message: managementErrorMessage(error),
          onRetry: () => ref.invalidate(codePulseTermsProvider),
        ),
        data: (terms) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(codePulseClassroomsProvider.future),
              ref.refresh(codePulseTermsProvider.future),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              const ManagementPageHeader(
                title: 'Lớp DSA',
                subtitle:
                    'Admin quản lý lớp, học kỳ và phân công giảng viên. Nội dung bài tập được quản lý bởi lecturer được giao.',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed:
                      terms
                          .where((term) => term.endDate.isAfter(DateTime.now()))
                          .isEmpty
                      ? null
                      : () => _editClassroom(
                          context,
                          ref,
                          terms
                              .where(
                                (term) => term.endDate.isAfter(DateTime.now()),
                              )
                              .toList(),
                        ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo lớp'),
                ),
              ),
              const SizedBox(height: 12),
              if (classrooms.isEmpty)
                const SizedBox(
                  height: 220,
                  child: ManagementEmpty(
                    title: 'Chưa có lớp DSA',
                    message:
                        'Tạo term trước, sau đó mở lớp trong term còn hạn.',
                  ),
                )
              else
                for (final classroom in classrooms) ...[
                  _ClassroomCard(
                    classroom: classroom,
                    onEdit: () =>
                        _editClassroom(context, ref, terms, classroom),
                    onDelete: () => _deleteClassroom(context, ref, classroom),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editClassroom(
  BuildContext context,
  WidgetRef ref,
  List<CodePulseTerm> terms, [
  CodePulseClassroom? classroom,
]) async {
  final values = await showDialog<Map<String, String?>>(
    context: context,
    builder: (_) => _ClassroomDialog(terms: terms, classroom: classroom),
  );
  if (values == null) return;
  try {
    final repository = ref.read(codePulseRepositoryProvider);
    if (classroom == null) {
      await repository.createClassroom(
        termId: values['termId']!,
        name: values['name']!,
        description: values['description']!,
        lecturerEmail: values['lecturerEmail'],
      );
    } else {
      final patch = Map<String, Object?>.from(values);
      if (patch['termId'] == classroom.termId) patch.remove('termId');
      await repository.updateClassroom(classroom.id, patch);
    }
    ref.invalidate(codePulseClassroomsProvider);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
  }
}

Future<void> _deleteClassroom(
  BuildContext context,
  WidgetRef ref,
  CodePulseClassroom classroom,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa lớp DSA?'),
      content: Text(
        'Xóa "${classroom.name}" sẽ xóa cả membership, workspace, LAB và assignment versions liên quan theo backend. Thao tác này không khôi phục được.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Giữ lại'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Xóa lớp'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(codePulseRepositoryProvider).deleteClassroom(classroom.id);
    ref.invalidate(codePulseClassroomsProvider);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.classroom,
    required this.onEdit,
    required this.onDelete,
  });
  final CodePulseClassroom classroom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  classroom.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ManagementStatus(status: classroom.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(classroom.termName ?? classroom.termId),
          if (classroom.description.isNotEmpty) Text(classroom.description),
          Text('Lecturer: ${classroom.lecturerEmail ?? 'Chưa phân công'}'),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ClassroomDialog extends StatefulWidget {
  const _ClassroomDialog({required this.terms, this.classroom});
  final List<CodePulseTerm> terms;
  final CodePulseClassroom? classroom;

  @override
  State<_ClassroomDialog> createState() => _ClassroomDialogState();
}

class _ClassroomDialogState extends State<_ClassroomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.classroom?.name ?? '');
  late final _description = TextEditingController(
    text: widget.classroom?.description ?? '',
  );
  late final _lecturerEmail = TextEditingController(
    text: widget.classroom?.lecturerEmail ?? '',
  );
  late String _termId = widget.classroom?.termId ?? _validTerms.first.id;
  late String _status = widget.classroom?.status ?? 'DRAFT';

  List<CodePulseTerm> get _validTerms => widget.terms
      .where(
        (term) =>
            term.endDate.isAfter(DateTime.now()) ||
            term.id == widget.classroom?.termId,
      )
      .toList(growable: false);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _lecturerEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.classroom == null ? 'Tạo lớp DSA' : 'Sửa lớp DSA'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _termId,
              decoration: const InputDecoration(labelText: 'Học kỳ'),
              items: [
                for (final term in _validTerms)
                  DropdownMenuItem(
                    value: term.id,
                    child: Text(term.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _termId = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên lớp'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nhập tên lớp.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _lecturerEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email lecturer (không bắt buộc)',
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isNotEmpty && !text.contains('@')) {
                  return 'Email chưa hợp lệ.';
                }
                return null;
              },
            ),
            if (widget.classroom != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Bản nháp')),
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Text('Đang hoạt động'),
                  ),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('Lưu trữ')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu')),
    ],
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, String?>{
      'termId': _termId,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'lecturerEmail': _lecturerEmail.text.trim().isEmpty
          ? null
          : _lecturerEmail.text.trim(),
      if (widget.classroom != null) 'status': _status,
    });
  }
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
