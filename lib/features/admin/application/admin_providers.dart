import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/codepulse_models.dart';
import '../data/codepulse_repository.dart';

final codePulseRepositoryProvider = Provider<CodePulseRepository>((ref) {
  return CodePulseRepository(ref.watch(apiClientProvider));
});

final codePulseTermsProvider = FutureProvider.autoDispose<List<CodePulseTerm>>((
  ref,
) {
  return ref.watch(codePulseRepositoryProvider).getTerms();
});

final codePulseClassroomsProvider =
    FutureProvider.autoDispose<List<CodePulseClassroom>>((ref) {
      return ref.watch(codePulseRepositoryProvider).getClassrooms();
    });
