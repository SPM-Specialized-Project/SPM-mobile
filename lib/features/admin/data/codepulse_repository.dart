import 'package:dio/dio.dart';

import 'codepulse_models.dart';

const dsaCourseId = '13';

class CodePulseRepository {
  const CodePulseRepository(this._dio);

  final Dio _dio;

  Future<List<CodePulseTerm>> getTerms() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/codepulse/terms',
      queryParameters: const {'courseId': dsaCourseId},
    );
    return _items(
      response.data,
      'terms',
    ).map(CodePulseTerm.fromJson).toList(growable: false);
  }

  Future<CodePulseTerm> createTerm({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime resetDate,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/codepulse/terms',
      queryParameters: const {'courseId': dsaCourseId},
      data: {
        'name': name.trim(),
        'startDate': _dateOnly(startDate),
        'endDate': _dateOnly(endDate),
        'resetDate': _dateOnly(resetDate),
      },
    );
    return CodePulseTerm.fromJson(_item(response.data, 'term'));
  }

  Future<CodePulseTerm> updateTerm(
    String id,
    Map<String, Object?> patch,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/codepulse/terms/${Uri.encodeComponent(id)}',
      queryParameters: const {'courseId': dsaCourseId},
      data: {'patch': patch},
    );
    return CodePulseTerm.fromJson(_item(response.data, 'term'));
  }

  Future<void> deleteTerm(String id) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/codepulse/terms/${Uri.encodeComponent(id)}',
      queryParameters: const {'courseId': dsaCourseId},
    );
  }

  Future<List<CodePulseClassroom>> getClassrooms() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/codepulse/classrooms',
      queryParameters: const {'courseId': dsaCourseId},
    );
    return _items(
      response.data,
      'classrooms',
    ).map(CodePulseClassroom.fromJson).toList(growable: false);
  }

  Future<CodePulseClassroom> createClassroom({
    required String termId,
    required String name,
    required String description,
    String? lecturerEmail,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/codepulse/classrooms',
      queryParameters: const {'courseId': dsaCourseId},
      data: {
        'termId': termId,
        'name': name.trim(),
        'description': description.trim(),
        if (lecturerEmail != null && lecturerEmail.trim().isNotEmpty)
          'lecturerEmail': lecturerEmail.trim(),
      },
    );
    return CodePulseClassroom.fromJson(_item(response.data, 'classroom'));
  }

  Future<CodePulseClassroom> updateClassroom(
    String id,
    Map<String, Object?> patch,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/codepulse/classrooms/${Uri.encodeComponent(id)}',
      queryParameters: const {'courseId': dsaCourseId},
      data: {'patch': patch},
    );
    return CodePulseClassroom.fromJson(_item(response.data, 'classroom'));
  }

  Future<void> deleteClassroom(String id) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/codepulse/classrooms/${Uri.encodeComponent(id)}',
      queryParameters: const {'courseId': dsaCourseId},
    );
  }
}

List<Map<String, dynamic>> _items(Map<String, dynamic>? data, String field) {
  final value = _body(data, field)['items'];
  if (value is! List) {
    throw FormatException('CodePulse $field must contain items.');
  }
  return [for (final item in value) _asMap(item, '$field item')];
}

Map<String, dynamic> _item(Map<String, dynamic>? data, String field) =>
    _asMap(_body(data, field)['item'], field);

Map<String, dynamic> _body(Map<String, dynamic>? data, String field) {
  if (data != null) return data;
  throw FormatException('Backend returned an empty CodePulse $field response.');
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('CodePulse $field must be an object.');
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
