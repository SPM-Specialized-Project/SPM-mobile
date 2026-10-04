import 'package:dio/dio.dart';
import '../../admin/data/codepulse_models.dart';

export '../../admin/data/codepulse_models.dart';

class DsaClassroomWorkspace {
  const DsaClassroomWorkspace({
    required this.assignments,
    required this.versions,
    required this.labs,
  });
  final List<Map<String, dynamic>> assignments, versions, labs;
}

class TutorDsaRepository {
  const TutorDsaRepository(this._dio);
  final Dio _dio;
  String _path(String id) =>
      '/api/codepulse/classrooms/${Uri.encodeComponent(id)}';

  Future<({List<CodePulseTerm> terms, List<CodePulseClassroom> classrooms})>
  getCatalog() async {
    final results = await Future.wait([
      _dio.get<Map<String, dynamic>>(
        '/api/codepulse/terms',
        queryParameters: {'courseId': '13'},
      ),
      _dio.get<Map<String, dynamic>>(
        '/api/codepulse/classrooms',
        queryParameters: {'courseId': '13'},
      ),
    ]);
    return (
      terms: _items(results[0]).map(CodePulseTerm.fromJson).toList(),
      classrooms: _items(results[1]).map(CodePulseClassroom.fromJson).toList(),
    );
  }

  Future<DsaClassroomWorkspace> getWorkspace(String id) async {
    final results = await Future.wait(
      ['assignments', 'assignment-versions', 'labs'].map(
        (resource) => _dio.get<Map<String, dynamic>>('${_path(id)}/$resource'),
      ),
    );
    return DsaClassroomWorkspace(
      assignments: _items(results[0]),
      versions: _items(results[1]),
      labs: _items(results[2]),
    );
  }

  Future<void> updateClassroom(String id, Map<String, dynamic> patch) async {
    await _dio.patch<Object?>(_path(id), data: {'patch': patch});
  }

  Future<Map<String, dynamic>> saveAssignment(
    String classroomId,
    String? id,
    Map<String, dynamic> data,
  ) async {
    final response = id == null
        ? await _dio.post<Map<String, dynamic>>(
            '${_path(classroomId)}/assignments',
            data: data,
          )
        : await _dio.patch<Map<String, dynamic>>(
            '${_path(classroomId)}/assignments/${Uri.encodeComponent(id)}',
            data: {'patch': data},
          );
    return _item(response);
  }

  Future<Map<String, dynamic>> assignmentAction(
    String classroomId,
    String id,
    String action,
  ) async => _item(
    await _dio.post<Map<String, dynamic>>(
      '${_path(classroomId)}/assignments/${Uri.encodeComponent(id)}/$action',
      data: {},
    ),
  );
  Future<void> deleteAssignment(String classroomId, String id) async {
    await _dio.delete<Object?>(
      '${_path(classroomId)}/assignments/${Uri.encodeComponent(id)}',
    );
  }

  Future<void> createLab(String classroomId, Map<String, dynamic> data) async {
    await _dio.post<Object?>('${_path(classroomId)}/labs', data: data);
  }

  Future<void> changeLabStatus(
    String classroomId,
    Map<String, dynamic> lab,
    String status,
  ) async {
    await _dio.patch<Object?>(
      '${_path(classroomId)}/labs/${Uri.encodeComponent(lab['id'] as String)}',
      data: {
        'status': status,
        'expectedStateVersion': lab['stateVersion'] ?? 0,
      },
    );
  }

  Future<void> updatePractice(
    String classroomId,
    String labId,
    Map<String, dynamic> assignment,
    Map<String, dynamic> patch,
  ) async {
    await _dio.patch<Object?>(
      '${_path(classroomId)}/labs/${Uri.encodeComponent(labId)}/assignments/${Uri.encodeComponent(assignment['id'] as String)}/practice-window',
      data: {
        ...patch,
        'expectedVersion': assignment['practiceWindowVersion'] ?? 0,
      },
    );
  }
}

List<Map<String, dynamic>> _items(Response<Map<String, dynamic>> response) =>
    (response.data!['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
Map<String, dynamic> _item(Response<Map<String, dynamic>> response) =>
    Map<String, dynamic>.from(response.data!['item'] as Map);
