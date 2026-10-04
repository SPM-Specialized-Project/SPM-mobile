import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/tutor/data/tutor_repository.dart';
import 'package:spm_mobile/features/tutor/data/tutor_dsa_repository.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course.dart';
import 'package:spm_mobile/features/tutor/domain/tutor_course_workspace.dart';

void main() {
  test(
    'course content sends preserved payload and revision without client ownership',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close());
      RequestOptions? captured;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            captured = request;
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'course': {'id': '13', 'title': 'DSA LAB'},
                  'detail': {
                    'content': (request.data as Map)['content'],
                    'permissions': {'canEdit': true},
                    'contentRevision': 4,
                  },
                },
              ),
            );
          },
        ),
      );
      final result = await TutorRepository(dio).saveCourseContent('13', [
        const TutorCourseSection(
          id: 'intro',
          type: 'introduction',
          title: 'Giới thiệu',
          data: {'text': 'Changed'},
        ),
      ], 3);
      expect(captured!.path, '/api/courses/13/detail');
      expect(captured!.method, 'PATCH');
      expect((captured!.data as Map)['expectedRevision'], 3);
      expect((captured!.data as Map).containsKey('viewerRole'), false);
      expect(result.sections.single.data['text'], 'Changed');
      expect(result.contentRevision, 4);
    },
  );

  test(
    'feedback and roster actions use authenticated course endpoints',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close());
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests.add(r);
            h.resolve(Response(requestOptions: r, data: {}));
          },
        ),
      );
      final repository = TutorRepository(dio);
      await repository.saveCourseFeedback(
        '13',
        const TutorCourseFeedback(
          courseComment: 'Good',
          revision: 2,
          studentComments: {'student@example.com': 'Progress'},
        ),
      );
      await repository.revokeCourseMember('13', 'member/13');
      await repository.addCourseMember('13', 'student@example.com');
      expect(requests[0].method, 'PATCH');
      expect((requests[0].data as Map)['expectedRevision'], 2);
      expect(requests[1].path, '/api/classrooms/13/memberships/member%2F13');
      expect(requests[2].method, 'POST');
      expect((requests[2].data as Map)['studentEmail'], 'student@example.com');
    },
  );

  test(
    'practice window and lab transitions send the current concurrency versions',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close());
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests.add(r);
            h.resolve(Response(requestOptions: r, data: {}));
          },
        ),
      );
      final repository = TutorDsaRepository(dio);
      await repository.updatePractice(
        'class-1',
        'lab-1',
        {'id': 'assignment-1', 'practiceWindowVersion': 7},
        {'status': 'CLOSED'},
      );
      await repository.changeLabStatus('class-1', {
        'id': 'lab-1',
        'stateVersion': 4,
      }, 'LIVE');
      expect(
        requests[0].path,
        '/api/codepulse/classrooms/class-1/labs/lab-1/assignments/assignment-1/practice-window',
      );
      expect((requests[0].data as Map)['expectedVersion'], 7);
      expect((requests[1].data as Map)['expectedStateVersion'], 4);
    },
  );
}
