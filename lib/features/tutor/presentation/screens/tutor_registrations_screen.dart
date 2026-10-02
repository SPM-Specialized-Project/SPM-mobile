import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_session.dart';
import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../../domain/tutor_registration.dart';
import '../widgets/tutor_ui.dart';

const _languages = <TutorOption>[
  TutorOption(id: 'vi', name: 'Tiếng Việt'),
  TutorOption(id: 'en', name: 'English'),
  TutorOption(id: 'cn', name: '简体中文'),
  TutorOption(id: 'th', name: 'ภาษาไทย'),
];

const _teachingModes = <TutorOption>[
  TutorOption(id: 'online', name: 'Trực tuyến'),
  TutorOption(id: 'hybrid', name: 'Kết hợp'),
];

const _teachingLocations = <TutorOption>[
  TutorOption(id: 'p1', name: 'Phường 1'),
  TutorOption(id: 'p2', name: 'Phường 2'),
  TutorOption(id: 'p3', name: 'Phường 3'),
  TutorOption(id: 'p4', name: 'Phường 4'),
];

class TutorRegistrationsScreen extends ConsumerWidget {
  const TutorRegistrationsScreen({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationsState = ref.watch(tutorRegistrationsProvider);
    return registrationsState.when(
      loading: () => const TutorLoadingView(),
      error: (error, _) => TutorErrorView(
        message: tutorErrorMessage(error),
        onRetry: () => ref.invalidate(tutorRegistrationsProvider),
      ),
      data: (registrations) =>
          _RegistrationsList(session: session, registrations: registrations),
    );
  }
}

class _RegistrationsList extends ConsumerWidget {
  const _RegistrationsList({
    required this.session,
    required this.registrations,
  });

  final AuthSession session;
  final List<TutorRegistration> registrations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...registrations]
      ..sort((left, right) {
        return (right.createdAt ?? DateTime(0)).compareTo(
          left.createdAt ?? DateTime(0),
        );
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .refresh(tutorRegistrationsProvider.future)
                .then<void>((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              TutorPageHeading(
                title: 'Hồ sơ tutor',
                subtitle: 'Đăng ký môn có thể dạy và hình thức hỗ trợ.',
              ),
              const SizedBox(height: 16),
              _RegistrationIntro(
                onCreate: () => _openForm(context, ref),
                enabled: true,
              ),
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
                  height: 230,
                  child: TutorEmptyView(
                    icon: Icons.assignment_outlined,
                    title: 'Chưa có hồ sơ',
                    message:
                        'Hồ sơ mới sẽ xuất hiện ở đây sau khi gửi thành công.',
                  ),
                )
              else
                for (final registration in sorted) ...[
                  _RegistrationCard(registration: registration),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    try {
      final courses = await ref.read(tutorCoursesProvider.future);
      if (!context.mounted) return;
      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần được phân công ít nhất một khóa học trước.'),
          ),
        );
        return;
      }

      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) =>
            _CreateTutorRegistrationSheet(session: session, courses: courses),
      );

      if (created == true) {
        ref.invalidate(tutorRegistrationsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi hồ sơ tutor.')));
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
    }
  }
}

class _RegistrationIntro extends StatelessWidget {
  const _RegistrationIntro({required this.onCreate, required this.enabled});

  final VoidCallback onCreate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cập nhật khả năng giảng dạy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn khóa học được giao, ngôn ngữ và hình thức bạn có thể hỗ trợ.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: enabled ? onCreate : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo hồ sơ dạy kèm'),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration});

  final TutorRegistration registration;

  @override
  Widget build(BuildContext context) {
    final date = registration.createdAt?.toLocal();
    final formattedDate = date == null
        ? 'Ngày gửi chưa có'
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                TutorStatusPill(status: registration.status),
              ],
            ),
            const SizedBox(height: 12),
            _OptionSummary(label: 'Môn', options: registration.subjects),
            _OptionSummary(label: 'Ngôn ngữ', options: registration.languages),
            _OptionSummary(
              label: 'Hình thức',
              options: registration.sessionTypes,
            ),
            if (registration.locations.isNotEmpty)
              _OptionSummary(label: 'Khu vực', options: registration.locations),
            if (registration.specialRequest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                registration.specialRequest,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionSummary extends StatelessWidget {
  const _OptionSummary({required this.label, required this.options});

  final String label;
  final List<TutorOption> options;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: ${options.map((item) => item.name).join(', ')}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _CreateTutorRegistrationSheet extends ConsumerStatefulWidget {
  const _CreateTutorRegistrationSheet({
    required this.session,
    required this.courses,
  });

  final AuthSession session;
  final List<TutorCourse> courses;

  @override
  ConsumerState<_CreateTutorRegistrationSheet> createState() =>
      _CreateTutorRegistrationSheetState();
}

class _CreateTutorRegistrationSheetState
    extends ConsumerState<_CreateTutorRegistrationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();
  final _linkController = TextEditingController();
  final Set<String> _selectedCourseIds = {};
  final Set<String> _selectedLanguageIds = {'vi'};
  final Set<String> _selectedModeIds = {'online'};
  final Set<String> _selectedLocationIds = {};
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _requestController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _toggle(Set<String> selected, String id, bool value) {
    setState(() {
      if (value) {
        selected.add(id);
      } else {
        selected.remove(id);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseIds.isEmpty ||
        _selectedLanguageIds.isEmpty ||
        _selectedModeIds.isEmpty ||
        (_selectedModeIds.contains('hybrid') && _selectedLocationIds.isEmpty)) {
      setState(() {
        _errorMessage =
            'Chọn ít nhất một môn, ngôn ngữ, hình thức và khu vực nếu dạy kết hợp.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(tutorRepositoryProvider)
          .createRegistration(
            session: widget.session,
            courses: widget.courses
                .where((course) => _selectedCourseIds.contains(course.id))
                .toList(growable: false),
            languages: _languages
                .where((option) => _selectedLanguageIds.contains(option.id))
                .toList(growable: false),
            sessionTypes: _teachingModes
                .where((option) => _selectedModeIds.contains(option.id))
                .toList(growable: false),
            locations: _teachingLocations
                .where((option) => _selectedLocationIds.contains(option.id))
                .toList(growable: false),
            specialRequest: _requestController.text,
            meetLink: _linkController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = tutorErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final showLocations = _selectedModeIds.contains('hybrid');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tạo hồ sơ tutor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.session.user.name} · ${widget.session.user.email}',
              ),
              const SizedBox(height: 18),
              _ChoiceSection<TutorCourse>(
                title: 'Môn có thể hỗ trợ',
                children: [
                  for (final course in widget.courses)
                    FilterChip(
                      label: Text(course.title),
                      selected: _selectedCourseIds.contains(course.id),
                      onSelected: _saving
                          ? null
                          : (selected) => _toggle(
                              _selectedCourseIds,
                              course.id,
                              selected,
                            ),
                    ),
                ],
              ),
              _ChoiceSection<TutorOption>(
                title: 'Ngôn ngữ',
                children: [
                  for (final option in _languages)
                    FilterChip(
                      label: Text(option.name),
                      selected: _selectedLanguageIds.contains(option.id),
                      onSelected: _saving
                          ? null
                          : (selected) => _toggle(
                              _selectedLanguageIds,
                              option.id,
                              selected,
                            ),
                    ),
                ],
              ),
              _ChoiceSection<TutorOption>(
                title: 'Hình thức dạy',
                children: [
                  for (final option in _teachingModes)
                    FilterChip(
                      label: Text(option.name),
                      selected: _selectedModeIds.contains(option.id),
                      onSelected: _saving
                          ? null
                          : (selected) =>
                                _toggle(_selectedModeIds, option.id, selected),
                    ),
                ],
              ),
              if (showLocations)
                _ChoiceSection<TutorOption>(
                  title: 'Khu vực có thể dạy trực tiếp',
                  children: [
                    for (final option in _teachingLocations)
                      FilterChip(
                        label: Text(option.name),
                        selected: _selectedLocationIds.contains(option.id),
                        onSelected: _saving
                            ? null
                            : (selected) => _toggle(
                                _selectedLocationIds,
                                option.id,
                                selected,
                              ),
                      ),
                  ],
                ),
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link trực tuyến (không bắt buộc)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                validator: (value) {
                  final input = value?.trim() ?? '';
                  if (input.isEmpty) return null;
                  final uri = Uri.tryParse(input);
                  if (uri == null ||
                      !['http', 'https'].contains(uri.scheme) ||
                      uri.host.isEmpty) {
                    return 'Link cần bắt đầu bằng http:// hoặc https://.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _requestController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Kinh nghiệm / yêu cầu đặc biệt',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Nhập một vài dòng giới thiệu khả năng hỗ trợ.'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gửi hồ sơ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 7),
          Wrap(spacing: 8, runSpacing: 2, children: children),
        ],
      ),
    );
  }
}
