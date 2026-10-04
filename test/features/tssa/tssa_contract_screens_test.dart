import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/features/tssa/data/tssa_repository.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_governance.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_profiles.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_screen.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_ui.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_workflows.dart';

// Captured from the real HTTP backend using synthetic, isolated accounts.
// These tests exercise rendering and contracts, not live network integration.
class ContractRepository extends TssaRepository {
  ContractRepository(this.responses) : super(Dio());
  final TssaData responses;
  final missing = <String>[];
  final reads = <String>[];

  @override
  Future<TssaData> read(String path) async {
    reads.add(path);
    final response = responses[path] as Map?;
    if (response == null) {
      missing.add(path);
      throw StateError('Missing synthetic API contract: $path');
    }
    final body = jsonDecode(jsonEncode(response['data'])) as TssaData;
    if ((response['status'] as int) >= 400) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: response['status'] as int,
          data: body,
        ),
      );
    }
    return body;
  }
}

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/tssa-contracts.json').readAsStringSync())
          as TssaData;
  final ids = fixture['ids'] as Map;
  final roles = fixture['roles'] as Map;
  TssaData responses(String role) => Map<String, dynamic>.from(roles[role]);
  TssaData identity(String role) =>
      Map<String, dynamic>.from((responses(role)['me'] as Map)['data'] as Map);
  TssaData request(String role) => Map<String, dynamic>.from(
    (responses(role)['requests/${ids['request']}'] as Map)['data'] as Map,
  );
  final cases = <(String, String, Widget Function(TssaData))>[
    (
      'learner',
      'profile',
      (me) => TssaLearnerPage(me: me, learnerId: ids['learner']),
    ),
    (
      'guardian',
      'profile',
      (me) => TssaLearnerPage(me: me, learnerId: ids['learner']),
    ),
    (
      'coordinator',
      'profile',
      (me) => TssaLearnerPage(me: me, learnerId: ids['learner']),
    ),
    (
      'learner',
      'consent',
      (me) => TssaConsentPage(me: me, learnerId: ids['learner']),
    ),
    (
      'guardian',
      'links',
      (me) => TssaList(
        title: 'Guardian–learner',
        children: [TssaLinks(me: me)],
      ),
    ),
    (
      'coordinator',
      'links',
      (me) => TssaList(
        title: 'Guardian–learner',
        children: [TssaLinks(me: me)],
      ),
    ),
    ('coordinator', 'tutors', (me) => TssaTutors(me: me)),
    ('learner', 'requests', (me) => TssaRequests(me: me)),
    ('coordinator', 'requests', (me) => TssaRequests(me: me)),
    (
      'learner',
      'request detail',
      (me) => TssaRequestPage(me: me, requestId: ids['request']),
    ),
    (
      'coordinator',
      'request detail',
      (me) => TssaRequestPage(me: me, requestId: ids['request']),
    ),
    (
      'coordinator',
      'matching review',
      (me) => TssaList(
        title: 'Contract shortlist',
        children: [TssaMatchReview(me: me, request: request('coordinator'))],
      ),
    ),
    ('learner', 'bookings', (me) => TssaBookings(me: me)),
    (
      'learner',
      'booking detail',
      (me) => TssaBookingPage(me: me, bookingId: ids['booking']),
    ),
    (
      'tutor',
      'booking detail',
      (me) => TssaBookingPage(me: me, bookingId: ids['booking']),
    ),
    (
      'coordinator',
      'booking detail',
      (me) => TssaBookingPage(me: me, bookingId: ids['booking']),
    ),
    (
      'learner',
      'privacy',
      (me) => TssaPrivacyPage(me: me, learnerId: ids['learner']),
    ),
    ('coordinator', 'privacy queue', (me) => TssaPrivacyQueue(me: me)),
    ('learner', 'support', (me) => TssaSupport(me: me)),
    (
      'coordinator',
      'case detail',
      (me) => TssaCasePage(me: me, caseId: ids['incident']),
    ),
    ('learner', 'notifications', (_) => const TssaNotifications()),
    ('learner', 'preferences', (_) => const TssaPreferences()),
    ('admin', 'governance', (me) => TssaGovernance(me: me)),
    ('admin', 'bindings', (me) => TssaBindings(me: me)),
    ('admin', 'models', (_) => const TssaModels()),
    ('admin', 'audit', (_) => const TssaAudit()),
    ('coordinator', 'metrics', (_) => const TssaMetrics()),
  ];
  for (final (role, name, builder) in cases) {
    testWidgets('CUI $role $name renders captured API contract at large text', (
      tester,
    ) async {
      expect(fixture['synthetic'], isTrue);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ContractRepository(responses(role));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tssaRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(body: builder(identity(role))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsWidgets);
      expect(repo.reads, isNotEmpty);
      // Build lazy children and nested views at the bottom as well as the top.
      for (var i = 0; i < 12; i++) {
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isEmpty) break;
        await tester.drag(scrollable.first, const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(repo.missing, isEmpty);
      expect(find.text('Thử lại'), findsNothing);
      if (role == 'coordinator' && name == 'profile') {
        expect(find.textContaining('PRIVATE-COMMUNICATION'), findsNothing);
        expect(find.text('Sửa hồ sơ học'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('CUI public information works without API or session', (
    tester,
  ) async {
    final repo = ContractRepository({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tssaRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: TssaPublicInfo())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn giữ quyền lựa chọn'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Khi mạng yếu'), findsOneWidget);
    expect(repo.reads, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
