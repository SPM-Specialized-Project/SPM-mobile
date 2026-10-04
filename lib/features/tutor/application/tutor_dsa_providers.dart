import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../data/tutor_dsa_repository.dart';

final tutorDsaRepositoryProvider = Provider(
  (ref) => TutorDsaRepository(ref.watch(apiClientProvider)),
);
final tutorDsaCatalogProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(tutorDsaRepositoryProvider).getCatalog(),
);
final tutorDsaWorkspaceProvider = FutureProvider.autoDispose
    .family<DsaClassroomWorkspace, String>(
      (ref, id) => ref.watch(tutorDsaRepositoryProvider).getWorkspace(id),
    );
