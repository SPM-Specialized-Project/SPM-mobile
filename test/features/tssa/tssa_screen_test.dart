import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/tssa/data/tssa_repository.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_screen.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_ui.dart';

class ScreenRepository extends TssaRepository {
  ScreenRepository() : super(Dio());
  bool denied = false;
  @override
  Future<TssaData> read(String path) async {
    if (denied) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 403,
          data: {'message': 'Quyền chia sẻ đã thu hồi.'},
        ),
      );
    }
    if (path == 'preferences') {
      return {'muted': [], 'reduceMotion': false, 'revision': 0};
    }
    if (path == 'governance/policy') {
      return {
        'revision': 0,
        'decisions': {
          for (var i = 1; i <= 12; i++)
            'D-${i.toString().padLeft(2, '0')}': {
              'status': 'OPEN',
              'decision': '',
            },
        },
        'releaseGates': <String, dynamic>{},
        'serviceGroups': [],
      };
    }
    if (path == 'governance/metrics') {
      return {
        'caseCount': 0,
        'modes': <String, dynamic>{},
        'requestedModes': <String, dynamic>{},
        'timeToShortlist': <String, dynamic>{},
        'effort': {
          'caseCoverage': {'numerator': 0, 'denominator': 0},
        },
        'subgroups': [],
        'overrideReasons': <String, dynamic>{},
        'rematchReasons': <String, dynamic>{},
        'incidentFirstResponse': <String, dynamic>{},
        'subgroupSuppression': 'Insufficient sample',
        for (final key in [
          'coverage',
          'eligibility',
          'noMatch',
          'override',
          'familyAccept',
          'completedFirstSession',
          'rematch',
          'missingness',
          'response',
        ])
          key: {'numerator': 0, 'denominator': 0, 'value': null},
      };
    }
    return {'items': []};
  }
}

void main() {
  final roles = {
    'learner': ['Hồ sơ', 'Yêu cầu', 'Lịch', 'Hỗ trợ'],
    'guardian': ['Hồ sơ', 'Yêu cầu', 'Lịch', 'Hỗ trợ'],
    'tutor': ['Hồ sơ', 'Ca được mời', 'Lịch', 'Hỗ trợ'],
    'coordinator': ['Queue', 'Xác minh', 'Lịch', 'Hỗ trợ'],
    'admin': ['Quản trị', 'Audit', 'Chất lượng', 'Hỗ trợ'],
  };
  for (final entry in roles.entries) {
    testWidgets(
      'UI01 ${entry.key} has correct tabs on 390px screen with large text',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final me = <String, dynamic>{
          'id': 'test@example.test',
          'role': entry.key,
          'policy': {'serviceGroups': [], 'decisions': {}, 'releaseGates': {}},
        };
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tssaRepositoryProvider.overrideWithValue(ScreenRepository()),
              tssaIdentityProvider.overrideWith((_) async => me),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const TssaScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<NavigationDestination>(
                find.byType(NavigationDestination),
              )
              .map((item) => item.label),
          entry.value,
        );
        await tester.tap(find.byType(NavigationDestination).at(2));
        await tester.pumpAndSettle();
        expect(find.text('TSSA · ${entry.value[2]}'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
  testWidgets(
    'UI02 unassigned role exposes onboarding with no privileged tabs',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tssaIdentityProvider.overrideWith(
              (_) async => {'id': 'test', 'role': 'unassigned'},
            ),
          ],
          child: const MaterialApp(home: TssaScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Chọn vai trò'), findsOneWidget);
    },
  );
  testWidgets(
    'UI03 denied refresh replaces old data and background hides sensitive view',
    (tester) async {
      final repo = ScreenRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tssaRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: TssaView(
                path: 'learners/private/profile',
                poll: true,
                builder: (data, reload) => TextButton(
                  onPressed: reload,
                  child: const Text('SENSITIVE PROFILE'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SENSITIVE PROFILE'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('SENSITIVE PROFILE'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('SENSITIVE PROFILE'), findsOneWidget);
      repo.denied = true;
      await tester.tap(find.text('SENSITIVE PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('SENSITIVE PROFILE'), findsNothing);
      expect(find.text('Quyền chia sẻ đã thu hồi.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
