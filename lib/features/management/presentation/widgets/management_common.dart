import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String managementErrorMessage(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map<String, dynamic> && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.response?.statusCode == 403) {
      return 'Backend từ chối thao tác này theo quyền của tài khoản.';
    }
    return 'Không kết nối được máy chủ. Kiểm tra backend rồi thử lại.';
  }
  if (error is FormatException) return 'Dữ liệu backend chưa đúng định dạng.';
  return 'Đã xảy ra lỗi. Vui lòng thử lại.';
}

class ManagementLoading extends StatelessWidget {
  const ManagementLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ManagementError extends StatelessWidget {
  const ManagementError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử tải lại'),
          ),
        ],
      ),
    ),
  );
}

class ManagementEmpty extends StatelessWidget {
  const ManagementEmpty({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class ManagementStatus extends StatelessWidget {
  const ManagementStatus({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (foreground, background) = switch (normalized) {
      'approved' ||
      'active' ||
      'completed' => (const Color(0xFF137547), const Color(0xFFE5F5EC)),
      'rejected' ||
      'declined' ||
      'archived' ||
      'cancelled' => (const Color(0xFFB3261E), const Color(0xFFFCE8E6)),
      _ => (const Color(0xFF805500), const Color(0xFFFFF3CD)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _label(normalized),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _label(String value) => switch (value) {
    'pending' => 'Chờ xử lý',
    'approved' => 'Đã duyệt',
    'rejected' || 'declined' => 'Từ chối',
    'active' => 'Đang hoạt động',
    'draft' => 'Bản nháp',
    'archived' => 'Đã lưu trữ',
    'scheduled' => 'Sắp diễn ra',
    'cancelled' => 'Đã hủy',
    'completed' => 'Hoàn thành',
    _ => status.isEmpty ? 'Chưa rõ' : status,
  };
}

class ManagementPageHeader extends StatelessWidget {
  const ManagementPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
