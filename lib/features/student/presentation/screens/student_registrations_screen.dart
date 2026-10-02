import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_session.dart';
import '../../../learning/domain/course.dart';
import '../../../tutor/presentation/widgets/tutor_ui.dart';
import '../../application/student_providers.dart';
import '../../data/student_registration.dart';

const _languages = <StudentOption>[
  StudentOption(id: 'vi', name: 'Tiếng Việt'),
  StudentOption(id: 'en', name: 'English'),
  StudentOption(id: 'cn', name: '简体中文'),
  StudentOption(id: 'th', name: 'ภาษาไทย'),
];

const _sessionTypes = <StudentOption>[
  StudentOption(id: 'online', name: 'Trực tuyến'),
  StudentOption(id: 'hybrid', name: 'Kết hợp'),
];

const _locations = <StudentOption>[
  StudentOption(id: 'p1', name: 'Phường 1'),
  StudentOption(id: 'p2', name: 'Phường 2'),
  StudentOption(id: 'p3', name: 'Phường 3'),
  StudentOption(id: 'p4', name: 'Phường 4'),
];

class StudentRegistrationsScreen extends ConsumerWidget {
  const StudentRegistrationsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref.watch(studentRegistrationsProvider);
    final courses = ref.watch(studentCoursesProvider);
    return registrations.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(studentRegistrationsProvider),
      ),
      data: (items) => courses.when(
        loading: () => const TutorLoadingView(),
        error: (error, _) => TutorErrorView(
          message: tutorErrorMessage(error),
          onRetry: () => ref.invalidate(studentCoursesProvider),
        ),
        data: (availableCourses) => _RegistrationList(
          session: session,
          items: items,
          courses: availableCourses,
        ),
      ),
    );
  }
}

class _RegistrationList extends ConsumerWidget {
  const _RegistrationList({
    required this.session,
    required this.items,
    required this.courses,
  });

  final AuthSession session;
  final List<StudentRegistration> items;
  final List<Course> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...items]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(studentRegistrationsProvider.future),
          ref.refresh(studentCoursesProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            'Đăng ký hỗ trợ học tập',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Gửi yêu cầu hỗ trợ cho một môn đang học và theo dõi trạng thái xử lý.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person_outline_rounded),
              ),
              title: Text(session.user.name),
              subtitle: Text(session.user.email),
              trailing: const Icon(Icons.verified_user_outlined),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: courses.isEmpty ? null : () => _openForm(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo yêu cầu hỗ trợ'),
          ),
          if (courses.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Bạn cần có khóa học đang truy cập để chọn môn đăng ký.',
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Lịch sử đăng ký',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const SizedBox(
              height: 220,
              child: TutorEmptyView(
                icon: Icons.assignment_outlined,
                title: 'Chưa có yêu cầu',
                message:
                    'Yêu cầu của bạn sẽ xuất hiện ở đây sau khi gửi thành công.',
              ),
            )
          else
            for (final registration in sorted) ...[
              _RegistrationCard(registration: registration),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _StudentRegistrationForm(session: session, courses: courses),
    );
    if (created == true) ref.invalidate(studentRegistrationsProvider);
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration});

  final StudentRegistration registration;

  @override
  Widget build(BuildContext context) {
    final courseNames = registration.subjects
        .map((item) => item.name)
        .join(', ');
    final createdAt = registration.createdAt;
    return Card(
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
                    courseNames.isEmpty ? 'Yêu cầu hỗ trợ' : courseNames,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TutorStatusPill(status: registration.status),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 7),
              Text(
                'Tạo ngày ${createdAt.toLocal().day.toString().padLeft(2, '0')}/${createdAt.toLocal().month.toString().padLeft(2, '0')}/${createdAt.toLocal().year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 9),
            Text(
              'Hình thức: ${registration.sessionTypes.map((e) => e.name).join(', ')} · Ngôn ngữ: ${registration.languages.map((e) => e.name).join(', ')}',
            ),
            if (registration.specialRequest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(registration.specialRequest),
            ],
            if (registration.declineReason != null &&
                registration.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do từ chối: ${registration.declineReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentRegistrationForm extends ConsumerStatefulWidget {
  const _StudentRegistrationForm({
    required this.session,
    required this.courses,
  });

  final AuthSession session;
  final List<Course> courses;

  @override
  ConsumerState<_StudentRegistrationForm> createState() =>
      _StudentRegistrationFormState();
}

class _StudentRegistrationFormState
    extends ConsumerState<_StudentRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();
  late String _courseId = widget.courses.first.id;
  StudentOption _language = _languages.first;
  StudentOption _sessionType = _sessionTypes.first;
  StudentOption? _location;
  bool _saving = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yêu cầu tutor hỗ trợ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Thông tin định danh lấy từ phiên đăng nhập, không tự nhập hoặc giả lập tên/email.',
              ),
              const SizedBox(height: 16),
              _DropdownField<Course>(
                label: 'Môn học',
                value: widget.courses.firstWhere(
                  (course) => course.id == _courseId,
                ),
                items: widget.courses,
                display: (course) => '${course.code} · ${course.title}',
                onChanged: (course) => setState(() => _courseId = course.id),
              ),
              const SizedBox(height: 12),
              _DropdownField<StudentOption>(
                label: 'Ngôn ngữ',
                value: _language,
                items: _languages,
                display: (item) => item.name,
                onChanged: (value) => setState(() => _language = value),
              ),
              const SizedBox(height: 12),
              _DropdownField<StudentOption>(
                label: 'Hình thức',
                value: _sessionType,
                items: _sessionTypes,
                display: (item) => item.name,
                onChanged: (value) => setState(() {
                  _sessionType = value;
                  if (value.id == 'online') _location = null;
                }),
              ),
              if (_sessionType.id == 'hybrid') ...[
                const SizedBox(height: 12),
                _DropdownField<StudentOption>(
                  label: 'Địa điểm mong muốn',
                  value: _location,
                  items: _locations,
                  display: (item) => item.name,
                  onChanged: (value) => setState(() => _location = value),
                  allowNull: true,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _requestController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Bạn cần hỗ trợ nội dung gì?',
                  alignLabelWithHint: true,
                  hintText: 'Nêu rõ chủ đề hoặc khó khăn để tutor chuẩn bị.',
                ),
                validator: (value) => (value ?? '').trim().length < 10
                    ? 'Mô tả ít nhất 10 ký tự để tutor hiểu yêu cầu.'
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
    setState(() => _saving = true);
    try {
      final course = widget.courses.firstWhere((item) => item.id == _courseId);
      await ref
          .read(studentRepositoryProvider)
          .createRegistration(
            session: widget.session,
            course: course,
            language: _language,
            sessionType: _sessionType,
            location: _location,
            specialRequest: _requestController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
    this.allowNull = false,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T> onChanged;
  final bool allowNull;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final item in items)
        DropdownMenuItem<T>(
          value: item,
          child: Text(display(item), overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
    validator: allowNull
        ? null
        : (selected) => selected == null ? 'Hãy chọn $label.' : null,
  );
}
