import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/management_providers.dart';
import '../../data/management_models.dart';
import '../widgets/management_common.dart';

class ManagerRegistrationsScreen extends ConsumerWidget {
  const ManagerRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerRegistrationsProvider);
    return state.when(
      loading: () => const ManagementLoading(),
      error: (error, _) => ManagementError(
        message: managementErrorMessage(error),
        onRetry: () => ref.invalidate(managerRegistrationsProvider),
      ),
      data: (registrations) {
        final sorted = [...registrations]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
        return RefreshIndicator(
          onRefresh: () => ref.refresh(managerRegistrationsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const ManagementPageHeader(
                title: 'Quản lý đăng ký',
                subtitle:
                    'Danh sách tổng hợp do backend cấp. Thao tác duyệt phụ thuộc permissions của từng hồ sơ.',
              ),
              if (sorted.isEmpty)
                const SizedBox(
                  height: 240,
                  child: ManagementEmpty(
                    title: 'Chưa có hồ sơ',
                    message: 'Backend chưa trả đăng ký nào.',
                  ),
                )
              else
                for (final item in sorted) ...[
                  _RegistrationCard(
                    registration: item,
                    onReview: () => _review(context, ref, item),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    ManagedRegistration registration,
  ) async {
    final reasonController = TextEditingController(
      text: registration.declineReason ?? '',
    );
    var status = registration.status;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật trạng thái hồ sơ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Chờ xử lý')),
                  DropdownMenuItem(value: 'Approved', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'Declined', child: Text('Từ chối')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lý do (nếu từ chối)',
                ),
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
    if (result == true) {
      try {
        await ref
            .read(managementRepositoryProvider)
            .updateRegistration(
              id: registration.id,
              status: status,
              reason: reasonController.text,
            );
        ref.invalidate(managerRegistrationsProvider);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(managementErrorMessage(error))));
      }
    }
    reasonController.dispose();
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration, required this.onReview});

  final ManagedRegistration registration;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (registration.type) {
      'student' => 'Sinh viên',
      'tutor' || 'lecturer' => 'Tutor',
      _ => registration.type,
    };
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
                    registration.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ManagementStatus(status: registration.status),
              ],
            ),
            const SizedBox(height: 3),
            Text('$typeLabel · ${registration.email}'),
            if (registration.summary.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(registration.summary),
            ],
            if (registration.specialRequest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(registration.specialRequest),
            ],
            if (registration.declineReason != null &&
                registration.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Lý do: ${registration.declineReason}'),
            ],
            if (registration.canEdit) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Cập nhật'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
