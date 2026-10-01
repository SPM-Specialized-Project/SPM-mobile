import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../application/backend_health_provider.dart';

class BackendStatusScreen extends ConsumerWidget {
  const BackendStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(backendHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kết nối backend')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: health.when(
            data: (result) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text('Kết nối thành công'),
                const SizedBox(height: 8),
                Text('Service: ${result.service}'),
                Text('API: ${AppConfig.apiBaseUrl}/api/health'),
              ],
            ),
            error: (error, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                const Text('Chưa kết nối được backend'),
                const SizedBox(height: 8),
                SelectableText(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('API: ${AppConfig.apiBaseUrl}/api/health'),
              ],
            ),
            loading: () => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Đang kiểm tra backend...'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.invalidate(backendHealthProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Thử lại'),
      ),
    );
  }
}
