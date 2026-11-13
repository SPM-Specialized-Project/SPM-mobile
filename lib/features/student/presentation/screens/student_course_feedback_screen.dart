import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../auth/data/auth_session.dart';

class StudentCourseFeedbackScreen extends StatefulWidget {
  const StudentCourseFeedbackScreen({
    required this.courseId,
    required this.courseTitle,
    required this.instructor,
    required this.session,
    super.key,
  });

  final String courseId;
  final String courseTitle;
  final String instructor;
  final AuthSession session;

  @override
  State<StudentCourseFeedbackScreen> createState() =>
      _StudentCourseFeedbackScreenState();
}

class _StudentCourseFeedbackScreenState
    extends State<StudentCourseFeedbackScreen> {
  static const _storage = FlutterSecureStorage();
  static const _criteria = <(String, String)>[
    ('concepts', 'Nắm vững các khái niệm về cấu trúc dữ liệu.'),
    ('analysis', 'Phân tích được độ phức tạp thời gian và bộ nhớ.'),
    ('algorithm', 'Chọn và áp dụng thuật toán phù hợp cho bài toán.'),
    ('implementation', 'Cài đặt lời giải rõ ràng, đúng và dễ bảo trì.'),
    ('testing', 'Kiểm thử các trường hợp biên và dữ liệu lỗi.'),
    ('debugging', 'Tự phát hiện và sửa lỗi trong quá trình thực hành.'),
    ('explanation', 'Giải thích được ý tưởng và quyết định kỹ thuật.'),
    ('progress', 'Có tiến bộ qua các bài thực hành trong học kỳ.'),
  ];

  final _commentController = TextEditingController();
  final _ratings = <String, int>{for (final item in _criteria) item.$1: 0};
  Map<String, int> _savedRatings = const {};
  String _savedComment = '';
  bool _loading = true;
  bool _saving = false;
  DateTime? _savedAt;
  String? _error;

  String get _storageKey {
    final identity =
        '${widget.session.user.email.trim().toLowerCase()}:${widget.courseId}';
    final encoded = base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
    return 'spm_course_rating_v1_$encoded';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final storedRatings = decoded['ratings'];
          if (storedRatings is Map) {
            for (final item in _criteria) {
              final value = storedRatings[item.$1];
              if (value is int && value >= 0 && value <= 5) {
                _ratings[item.$1] = value;
              }
            }
          }
          final comment = decoded['comment'];
          if (comment is String) {
            _commentController.text = comment;
            _savedComment = comment;
          }
          _savedRatings = Map<String, int>.from(_ratings);
          final savedAt = decoded['savedAt'];
          if (savedAt is String) _savedAt = DateTime.tryParse(savedAt);
        }
      }
    } catch (_) {
      _error = 'Không thể đọc đánh giá đã lưu trên thiết bị.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final savedAt = DateTime.now().toUtc();
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode({
          'version': 1,
          'courseId': widget.courseId,
          'ratings': _ratings,
          'comment': _commentController.text.trim(),
          'savedAt': savedAt.toIso8601String(),
        }),
      );
      if (!mounted) return;
      setState(() {
        _savedAt = savedAt;
        _savedRatings = Map<String, int>.from(_ratings);
        _savedComment = _commentController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đánh giá trên thiết bị này.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu đánh giá trên thiết bị.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Đánh giá môn học',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text('Chia sẻ trải nghiệm của bạn về ${widget.courseTitle}.'),
        const SizedBox(height: 4),
        Text(
          'Giảng viên: ${widget.instructor}',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          color: colors.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đánh giá được mã hóa và lưu trên thiết bị này. Hiện chưa có API để gửi hoặc chia sẻ đánh giá.',
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: colors.surfaceContainerHighest,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Mức độ đạt được',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var index = 0; index < _criteria.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_criteria[index].$2),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 2,
                          children: [
                            for (var value = 1; value <= 5; value++)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: '$value trên 5',
                                onPressed: () => setState(
                                  () => _ratings[_criteria[index].$1] = value,
                                ),
                                icon: Icon(
                                  value <= _ratings[_criteria[index].$1]!
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: value <= _ratings[_criteria[index].$1]!
                                      ? colors.tertiary
                                      : colors.outline,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Nhận xét về giảng viên',
              hintText: 'Chia sẻ điều hữu ích và điều có thể cải thiện',
              alignLabelWithHint: true,
            ),
          ),
          if (_savedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lưu trên thiết bị lúc ${MaterialLocalizations.of(context).formatShortDate(_savedAt!.toLocal())}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => StudentCourseFeedbackDetailScreen(
                    courseTitle: widget.courseTitle,
                    instructor: widget.instructor,
                    ratings: [
                      for (final criterion in _criteria)
                        (criterion.$2, _savedRatings[criterion.$1] ?? 0),
                    ],
                    comment: _savedComment,
                    savedAt: _savedAt!,
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Xem đánh giá đã lưu'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu đánh giá'),
          ),
        ],
      ],
    );
  }
}

class StudentCourseFeedbackDetailScreen extends StatelessWidget {
  const StudentCourseFeedbackDetailScreen({
    required this.courseTitle,
    required this.instructor,
    required this.ratings,
    required this.comment,
    required this.savedAt,
    super.key,
  });

  final String courseTitle;
  final String instructor;
  final List<(String, int)> ratings;
  final String comment;
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đánh giá')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Text(
            courseTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Giảng viên: $instructor'),
          Text(
            'Lưu trên thiết bị · ${MaterialLocalizations.of(context).formatMediumDate(savedAt.toLocal())}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: colors.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Đây là bản cá nhân đã lưu trên thiết bị này. Chưa có API đánh giá để gửi hoặc chia sẻ với khóa học.',
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Mức độ tự đánh giá',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < ratings.length; index++) ...[
                  if (index > 0) const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(ratings[index].$1),
                    subtitle: Text(
                      ratings[index].$2 == 0
                          ? 'Chưa chọn mức đánh giá'
                          : '${ratings[index].$2} trên 5',
                    ),
                    trailing: ratings[index].$2 == 0
                        ? null
                        : Icon(Icons.star_rounded, color: colors.tertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nhận xét',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                comment.isEmpty ? 'Chưa có nhận xét.' : comment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
