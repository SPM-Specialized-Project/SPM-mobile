import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/backend_health.dart';
import '../data/backend_health_repository.dart';

final backendHealthRepositoryProvider = Provider<BackendHealthRepository>((
  ref,
) {
  return BackendHealthRepository(ref.watch(apiClientProvider));
});

final backendHealthProvider = FutureProvider<BackendHealth>((ref) {
  return ref.watch(backendHealthRepositoryProvider).check();
});
