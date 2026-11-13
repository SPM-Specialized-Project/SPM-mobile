import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../data/assistant_repository.dart';
import '../data/assistant_knowledge.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(apiClientProvider));
});

final assistantKnowledgeProvider = FutureProvider<AssistantKnowledge>((
  ref,
) async {
  return AssistantKnowledge(await AssistantKnowledge.load());
});
