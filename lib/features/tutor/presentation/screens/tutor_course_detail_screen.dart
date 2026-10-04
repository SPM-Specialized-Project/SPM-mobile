import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/tutor_providers.dart';
import '../../domain/tutor_course.dart';
import '../widgets/tutor_ui.dart';
import '../widgets/tutor_course_content.dart';
import '../widgets/tutor_course_tabs.dart';
import '../widgets/tutor_dsa_tab.dart';
import 'tutor_submissions_screen.dart';

class TutorCourseDetailScreen extends ConsumerWidget {
  const TutorCourseDetailScreen({required this.courseId, super.key});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(tutorCourseDetailProvider(courseId))
      .when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Chi tiết khóa học')),
          body: const TutorLoadingView(),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Chi tiết khóa học')),
          body: TutorErrorView(
            message: tutorErrorMessage(error),
            onRetry: () => ref.invalidate(tutorCourseDetailProvider(courseId)),
          ),
        ),
        data: (detail) =>
            _CourseWorkspace(key: ValueKey(courseId), detail: detail),
      );
}

class _CourseWorkspace extends ConsumerStatefulWidget {
  const _CourseWorkspace({required this.detail, super.key});
  final TutorCourseDetail detail;
  @override
  ConsumerState<_CourseWorkspace> createState() => _CourseWorkspaceState();
}

class _CourseWorkspaceState extends ConsumerState<_CourseWorkspace> {
  bool _editing = false, _dirty = false, _saving = false;
  late List<TutorCourseSection> _sections = List.of(widget.detail.sections);
  late int _revision = widget.detail.contentRevision;

  @override
  void didUpdateWidget(covariant _CourseWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty) {
      _sections = List.of(widget.detail.sections);
      _revision = widget.detail.contentRevision;
    }
  }

  Future<bool> _discard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bỏ thay đổi chưa lưu?'),
            content: const Text('Nội dung bạn vừa chỉnh sửa chưa được lưu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tiếp tục sửa'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bỏ thay đổi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _toggleEditing() async {
    if (_editing && !await _discard()) return;
    if (!mounted) return;
    setState(() {
      _editing = !_editing;
      if (!_editing) {
        _dirty = false;
        _sections = List.of(widget.detail.sections);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(tutorRepositoryProvider)
          .saveCourseContent(widget.detail.course.id, _sections, _revision);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _revision = updated.contentRevision;
      });
      ref.invalidate(tutorCourseDetailProvider(widget.detail.course.id));
      ref.invalidate(tutorCourseSubmissionsProvider(widget.detail.course.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu nội dung môn học')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tutorErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final id = detail.course.id;
    return DefaultTabController(
      length: id == '13' ? 6 : 5,
      child: PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || _saving) return;
          if (await _discard() && context.mounted) {
            setState(() => _dirty = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.pop(context);
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              detail.course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (detail.canEdit)
                Tooltip(
                  message: _editing ? 'Tắt chỉnh sửa' : 'Chỉnh sửa',
                  child: TextButton.icon(
                    onPressed: _saving ? null : _toggleEditing,
                    icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                    label: Text(_editing ? 'Xong' : 'Chỉnh sửa'),
                  ),
                ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'Tổng quan'),
                const Tab(text: 'Danh sách lớp'),
                const Tab(text: 'Đánh giá'),
                if (id == '13') const Tab(text: 'Terms and classrooms'),
                const Tab(text: 'Bài nộp'),
                const Tab(text: 'Xem thống kê'),
              ],
            ),
          ),
          body: Column(
            children: [
              if (_editing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Text(
                    'Đang bật chỉnh sửa',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    TutorCourseContent(
                      course: detail.course,
                      sections: _sections,
                      editable: _editing && !_saving,
                      onChanged: (sections) => setState(() {
                        _sections = sections;
                        _dirty = true;
                      }),
                    ),
                    TutorCourseRosterTab(courseId: id, editable: _editing),
                    TutorCourseFeedbackTab(
                      course: detail.course,
                      editable: _editing,
                    ),
                    if (id == '13') TutorDsaTab(editable: _editing),
                    TutorSubmissionsScreen(courseId: id),
                    TutorCourseStatisticsTab(course: detail.course),
                  ],
                ),
              ),
              if (_dirty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    if (await _discard() && mounted) {
                                      setState(() {
                                        _dirty = false;
                                        _sections = List.of(
                                          widget.detail.sections,
                                        );
                                      });
                                    }
                                  },
                            child: const Text('Hủy thay đổi'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(
                              _saving ? 'Đang lưu...' : 'Lưu nội dung',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
