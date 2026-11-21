import 'package:dio/dio.dart';

import 'assistant_knowledge.dart';

class AssistantRepository {
  const AssistantRepository(this._dio);

  final Dio _dio;

  Future<AssistantReply> answer(String question) async {
    final response = await _dio.post<Object?>(
      '/api/assistant/messages',
      data: {'question': question},
    );
    final payload = response.data;
    if (payload is! Map) {
      throw const FormatException('Phản hồi trợ lý không đúng định dạng.');
    }

    final sources = <AssistantCitation>[];
    final rawSources = payload['sources'];
    if (rawSources is List) {
      for (final source in rawSources) {
        if (source is Map &&
            source['id'] is String &&
            source['section'] is String) {
          sources.add(
            AssistantCitation(
              id: source['id'] as String,
              section: source['section'] as String,
            ),
          );
        }
      }
    }

    String? readString(String key) =>
        payload[key] is String ? payload[key] as String : null;

    final status = readString('status');
    final answer = readString('answer');
    if (status == null || answer == null) {
      throw const FormatException(
        'Phản hồi trợ lý thiếu trạng thái hoặc nội dung.',
      );
    }
    return AssistantReply(
      status: status,
      answer: answer,
      sources: sources,
      title: readString('title'),
      note: readString('note'),
      featureStatus: readString('featureStatus'),
      mode: readString('mode'),
      destination: AssistantDestination.parse(readString('destination')),
    );
  }
}
