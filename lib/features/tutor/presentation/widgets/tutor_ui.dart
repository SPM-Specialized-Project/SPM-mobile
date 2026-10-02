import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

String tutorErrorMessage(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map<String, dynamic> && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.response?.statusCode == 403) {
      return 'Tài khoản hiện tại không có quyền thực hiện thao tác này.';
    }
    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.';
    }
    return 'Không kết nối được máy chủ. Kiểm tra backend rồi thử lại.';
  }
  if (error is FormatException) {
    return 'Dữ liệu backend trả về chưa đúng định dạng.';
  }
  return 'Đã xảy ra lỗi. Vui lòng thử lại.';
}

class TutorPageHeading extends StatelessWidget {
  const TutorPageHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class TutorLoadingView extends StatelessWidget {
  const TutorLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class TutorErrorView extends StatelessWidget {
  const TutorErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: colors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorEmptyView extends StatelessWidget {
  const TutorEmptyView({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorStatusPill extends StatelessWidget {
  const TutorStatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (label, foreground, background) = switch (normalized) {
      'graded' || 'approved' || 'completed' => (
        _statusLabel(normalized),
        const Color(0xFF137547),
        const Color(0xFFE5F5EC),
      ),
      'cancelled' || 'declined' => (
        _statusLabel(normalized),
        const Color(0xFFB3261E),
        const Color(0xFFFCE8E6),
      ),
      'not-submitted' => (
        'Chưa nộp',
        const Color(0xFF667085),
        const Color(0xFFF0F2F6),
      ),
      _ => (
        _statusLabel(normalized),
        const Color(0xFF805500),
        const Color(0xFFFFF3CD),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _statusLabel(String value) => switch (value) {
    'submitted' => 'Chờ chấm',
    'graded' => 'Đã chấm',
    'pending' => 'Đang chờ duyệt',
    'approved' => 'Đã duyệt',
    'declined' => 'Từ chối',
    'scheduled' => 'Sắp diễn ra',
    'completed' => 'Đã hoàn thành',
    'cancelled' => 'Đã hủy',
    _ => value.isEmpty ? 'Chưa rõ trạng thái' : value,
  };
}

class TutorBrandHero extends StatelessWidget {
  const TutorBrandHero({
    required this.name,
    required this.courseCount,
    required this.studentCount,
    super.key,
  });

  final String name;
  final int courseCount;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF4968FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260329E9),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KHU VỰC GIẢNG DẠY',
            style: TextStyle(
              color: Color(0xFFDCE4FF),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xin chào, $name',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 26,
            runSpacing: 12,
            children: [
              _HeroMetric(value: '$courseCount', label: 'Khóa đang dạy'),
              _HeroMetric(value: '$studentCount', label: 'Sinh viên'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: Color(0xFFDCE4FF))),
      ],
    );
  }
}
