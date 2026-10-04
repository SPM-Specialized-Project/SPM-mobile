class CourseMember {
  const CourseMember({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.canEdit,
  });
  final String id, name, email, status;
  final bool canEdit;
  factory CourseMember.fromJson(Map<String, dynamic> json) => CourseMember(
    id: json['id'] as String,
    name: json['studentName'] as String,
    email: json['studentEmail'] as String,
    status: json['status'] as String,
    canEdit: (json['permissions'] as Map<String, dynamic>?)?['canEdit'] == true,
  );
}

class CourseRoster {
  const CourseRoster({
    required this.members,
    required this.availableStudents,
    required this.canCreate,
  });
  final List<CourseMember> members;
  final List<Map<String, dynamic>> availableStudents;
  final bool canCreate;
  factory CourseRoster.fromJson(Map<String, dynamic> json) => CourseRoster(
    members: (json['items'] as List)
        .map(
          (item) =>
              CourseMember.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    availableStudents: (json['availableStudents'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    canCreate:
        (json['permissions'] as Map<String, dynamic>?)?['canCreate'] == true,
  );
}

class TutorCourseFeedback {
  const TutorCourseFeedback({
    this.courseComment = '',
    this.studentComments = const {},
    this.revision = 0,
  });
  final String courseComment;
  final Map<String, String> studentComments;
  final int revision;
  factory TutorCourseFeedback.fromJson(Map<String, dynamic> json) =>
      TutorCourseFeedback(
        courseComment: json['courseComment'] as String? ?? '',
        studentComments: Map<String, String>.from(
          json['studentComments'] as Map? ?? {},
        ),
        revision: json['revision'] as int? ?? 0,
      );
}
