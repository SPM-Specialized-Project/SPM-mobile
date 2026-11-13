import 'package:dio/dio.dart';

class StudentCodePulseClassroom {
  const StudentCodePulseClassroom({
    required this.id,
    required this.courseId,
    required this.termId,
    required this.name,
    required this.description,
    required this.status,
    this.termName,
  });

  final String id;
  final String courseId;
  final String termId;
  final String name;
  final String description;
  final String status;
  final String? termName;

  factory StudentCodePulseClassroom.fromJson(Map<String, dynamic> json) {
    final term = json['term'];
    return StudentCodePulseClassroom(
      id: _requiredText(json, 'id'),
      courseId: _requiredText(json, 'courseId'),
      termId: _requiredText(json, 'termId'),
      name: _requiredText(json, 'name'),
      description: _optionalText(json['description']) ?? '',
      status: _optionalText(json['status']) ?? 'ACTIVE',
      termName: term is Map<String, dynamic>
          ? _optionalText(term['name'])
          : null,
    );
  }
}

class StudentCodePulseAssignment {
  const StudentCodePulseAssignment({
    required this.id,
    required this.classroomId,
    required this.title,
    required this.description,
    required this.runtime,
    this.constraints,
    this.inputFormat,
    this.outputFormat,
    this.starterCode,
    this.examples = const [],
  });

  final String id;
  final String classroomId;
  final String title;
  final String description;
  final String runtime;
  final String? constraints;
  final String? inputFormat;
  final String? outputFormat;
  final String? starterCode;
  final List<StudentCodePulseExample> examples;

  factory StudentCodePulseAssignment.fromJson(Map<String, dynamic> json) {
    final rawTests = json['testCases'];
    final examples = rawTests is List
        ? rawTests
              .map((item) => _asMap(item, 'test case'))
              .where((item) => item['hidden'] != true)
              .map(StudentCodePulseExample.fromJson)
              .toList(growable: false)
        : const <StudentCodePulseExample>[];
    return StudentCodePulseAssignment(
      id: _requiredText(json, 'id'),
      classroomId: _requiredText(json, 'classroomId'),
      title: _requiredText(json, 'title'),
      description: _optionalText(json['description']) ?? '',
      runtime: _optionalText(json['runtime']) ?? 'PYTHON',
      constraints: _optionalText(json['constraints']),
      inputFormat: _optionalText(json['inputFormat']),
      outputFormat: _optionalText(json['outputFormat']),
      starterCode: _optionalText(json['starterCode']),
      examples: examples,
    );
  }
}

class StudentCodePulseExample {
  const StudentCodePulseExample({required this.input, required this.output});

  final String input;
  final String output;

  factory StudentCodePulseExample.fromJson(Map<String, dynamic> json) =>
      StudentCodePulseExample(
        input: _optionalText(json['input']) ?? '',
        output: _optionalText(json['expectedOutput']) ?? '',
      );
}

class StudentCodePulseHint {
  const StudentCodePulseHint({
    required this.id,
    required this.title,
    required this.revealed,
    this.content,
  });

  final String id;
  final String title;
  final bool revealed;
  final String? content;

  factory StudentCodePulseHint.fromJson(Map<String, dynamic> json) =>
      StudentCodePulseHint(
        id: _requiredText(json, 'id'),
        title: _requiredText(json, 'title'),
        revealed: json['revealed'] == true,
        content: _optionalText(json['content']),
      );
}

class StudentCodePulseLabAssignment {
  const StudentCodePulseLabAssignment({
    required this.id,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.runtime,
    required this.practiceAccess,
    this.accessReason,
    this.openAt,
    this.closeAt,
  });

  final String id;
  final String assignmentId;
  final String title;
  final String description;
  final String runtime;
  final String practiceAccess;
  final String? accessReason;
  final DateTime? openAt;
  final DateTime? closeAt;

  factory StudentCodePulseLabAssignment.fromJson(Map<String, dynamic> json) =>
      StudentCodePulseLabAssignment(
        id: _requiredText(json, 'id'),
        assignmentId: _requiredText(json, 'assignmentId'),
        title: _requiredText(json, 'title'),
        description: _optionalText(json['description']) ?? '',
        runtime:
            _optionalText(json['language']) ??
            _optionalText(json['runtime']) ??
            'PYTHON',
        practiceAccess: _optionalText(json['practiceAccess']) ?? 'CLOSED',
        accessReason: _optionalText(json['practiceAccessReason']),
        openAt: _optionalDate(json['openAt'] ?? json['open_at']),
        closeAt: _optionalDate(json['closeAt'] ?? json['close_at']),
      );
}

class StudentCodePulseLab {
  const StudentCodePulseLab({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.assignments,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<StudentCodePulseLabAssignment> assignments;

  factory StudentCodePulseLab.fromJson(Map<String, dynamic> json) {
    final rawAssignments = json['assignments'];
    final assignments = rawAssignments is List
        ? rawAssignments
              .map((item) => _asMap(item, 'lab assignment'))
              .map(StudentCodePulseLabAssignment.fromJson)
              .toList(growable: false)
        : const <StudentCodePulseLabAssignment>[];
    return StudentCodePulseLab(
      id: _requiredText(json, 'id'),
      name: _requiredText(json, 'name'),
      description: _optionalText(json['description']) ?? '',
      status: _optionalText(json['status']) ?? 'SCHEDULED',
      startAt: _optionalDate(json['startAt']),
      endAt: _optionalDate(json['endAt']),
      assignments: assignments,
    );
  }
}

class StudentCodePulseClassroomWork {
  const StudentCodePulseClassroomWork({
    required this.assignments,
    required this.labs,
  });

  final List<StudentCodePulseAssignment> assignments;
  final List<StudentCodePulseLab> labs;
}

class StudentCodePulseWorkspace {
  const StudentCodePulseWorkspace({
    required this.id,
    required this.sourceCode,
    this.executionResult,
    this.practiceWindow,
    this.updatedAt,
    this.hints = const [],
  });

  final String id;
  final String sourceCode;
  final Map<String, dynamic>? executionResult;
  final Map<String, dynamic>? practiceWindow;
  final DateTime? updatedAt;
  final List<StudentCodePulseHint> hints;

  StudentCodePulseWorkspace copyWith({
    String? sourceCode,
    DateTime? updatedAt,
  }) => StudentCodePulseWorkspace(
    id: id,
    sourceCode: sourceCode ?? this.sourceCode,
    executionResult: executionResult,
    practiceWindow: practiceWindow,
    updatedAt: updatedAt ?? this.updatedAt,
    hints: hints,
  );

  factory StudentCodePulseWorkspace.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? practiceWindow,
  }) {
    final rawExecution = json['executionResult'];
    final problem = json['problem'];
    final rawHints = problem is Map<String, dynamic> ? problem['hints'] : null;
    final hints = rawHints is List
        ? rawHints
              .map((item) => _asMap(item, 'hint'))
              .map(StudentCodePulseHint.fromJson)
              .toList(growable: false)
        : const <StudentCodePulseHint>[];
    return StudentCodePulseWorkspace(
      id: _requiredText(json, 'id'),
      sourceCode: _optionalText(json['sourceCode']) ?? '',
      updatedAt: _optionalDate(json['updatedAt']),
      executionResult: rawExecution is Map<String, dynamic>
          ? rawExecution
          : null,
      practiceWindow: practiceWindow,
      hints: hints,
    );
  }
}

class StudentCodePulseSubmission {
  const StudentCodePulseSubmission({
    required this.id,
    required this.passedCount,
    required this.totalCount,
    required this.score,
    required this.submittedAt,
  });

  final String id;
  final int passedCount;
  final int totalCount;
  final num score;
  final DateTime? submittedAt;

  factory StudentCodePulseSubmission.fromJson(Map<String, dynamic> json) {
    final submitted = json['submittedAt'];
    return StudentCodePulseSubmission(
      id: _requiredText(json, 'id'),
      passedCount: _integer(json['passedCount']),
      totalCount: _integer(json['totalCount']),
      score: json['score'] is num ? json['score'] as num : 0,
      submittedAt: submitted is String ? DateTime.tryParse(submitted) : null,
    );
  }
}

class StudentCodePulseRepository {
  const StudentCodePulseRepository(this._dio);

  final Dio _dio;

  Future<List<StudentCodePulseClassroom>> getClassrooms(String courseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/codepulse/classrooms',
      queryParameters: {'courseId': courseId},
    );
    return _items(
      response.data,
      'classrooms',
    ).map(StudentCodePulseClassroom.fromJson).toList(growable: false);
  }

  Future<List<StudentCodePulseAssignment>> getAssignments(
    String classroomId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}/assignments',
    );
    return _items(
      response.data,
      'assignments',
    ).map(StudentCodePulseAssignment.fromJson).toList(growable: false);
  }

  Future<StudentCodePulseClassroomWork> getClassroomWork(
    String classroomId,
  ) async {
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>(
        '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}/assignments',
      ),
      _dio.get<Map<String, dynamic>>(
        '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}/labs',
      ),
    ]);
    return StudentCodePulseClassroomWork(
      assignments: _items(
        responses[0].data,
        'assignments',
      ).map(StudentCodePulseAssignment.fromJson).toList(growable: false),
      labs: _items(
        responses[1].data,
        'labs',
      ).map(StudentCodePulseLab.fromJson).toList(growable: false),
    );
  }

  Future<StudentCodePulseWorkspace> getWorkspace({
    required String classroomId,
    required String assignmentId,
    String? labId,
    String? labAssignmentId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}/workspace',
      queryParameters: {
        'assignmentId': assignmentId,
        ...?_queryParameter('labId', labId),
        ...?_queryParameter('labAssignmentId', labAssignmentId),
      },
    );
    return StudentCodePulseWorkspace.fromJson(
      _item(response.data, 'workspace'),
      practiceWindow: _optionalMap(response.data?['practiceWindow']),
    );
  }

  Future<StudentCodePulseWorkspace> saveWorkspace({
    required String workspaceId,
    required String sourceCode,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/codepulse/workspaces/${Uri.encodeComponent(workspaceId)}',
      data: {'sourceCode': sourceCode},
    );
    return StudentCodePulseWorkspace.fromJson(
      _item(response.data, 'workspace'),
    );
  }

  Future<StudentCodePulseWorkspace> runCode({
    required String workspaceId,
    required String sourceCode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/codepulse/workspaces/${Uri.encodeComponent(workspaceId)}/execute',
      data: {'sourceCode': sourceCode},
    );
    return StudentCodePulseWorkspace.fromJson(
      _item(response.data, 'workspace'),
    );
  }

  Future<StudentCodePulseWorkspace> revealHint({
    required String workspaceId,
    required String hintId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/codepulse/workspaces/${Uri.encodeComponent(workspaceId)}'
      '/hints/${Uri.encodeComponent(hintId)}',
    );
    return StudentCodePulseWorkspace.fromJson(
      _item(response.data, 'workspace'),
    );
  }

  Future<StudentCodePulseSubmission> submit({
    required String classroomId,
    required String assignmentId,
    required String sourceCode,
    String? labId,
    String? labAssignmentId,
  }) async {
    final path = labId != null && labAssignmentId != null
        ? '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}'
              '/labs/${Uri.encodeComponent(labId)}'
              '/assignments/${Uri.encodeComponent(labAssignmentId)}/submit'
        : '/api/codepulse/classrooms/${Uri.encodeComponent(classroomId)}'
              '/assignments/${Uri.encodeComponent(assignmentId)}/submissions';
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'sourceCode': sourceCode},
    );
    return StudentCodePulseSubmission.fromJson(
      _item(response.data, 'submission'),
    );
  }
}

List<Map<String, dynamic>> _items(Map<String, dynamic>? data, String field) {
  final items = _body(data, field)['items'];
  if (items is! List) {
    throw FormatException('CodePulse $field must contain items.');
  }
  return [for (final item in items) _asMap(item, '$field item')];
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

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('CodePulse field "$key" must be a non-empty string.');
}

String? _optionalText(Object? value) => value is String ? value.trim() : null;

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic>? _optionalMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

Map<String, String>? _queryParameter(String key, String? value) =>
    value == null ? null : {key: value};

int _integer(Object? value) => value is num ? value.toInt() : 0;
