import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/core/security/draft_storage.dart';
import 'package:spm_mobile/features/tssa/data/tssa_repository.dart';
import 'package:spm_mobile/features/tssa/presentation/tssa_form.dart';

class FormRepository extends TssaRepository {
  FormRepository() : super(Dio());
  final bodies = <TssaData>[];
  final keys = <String?>[];
  Future<TssaData> Function()? submit;
  @override
  Future<TssaData> write(
    String path,
    TssaData data, {
    bool patch = false,
    String? key,
  }) async {
    bodies.add(Map.of(data));
    keys.add(key);
    return submit == null ? {'id': 'saved'} : await submit!();
  }
}

Future<void> open(
  WidgetTester tester,
  FormRepository repository,
  TssaFormScreen form,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tssaRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => form),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> send(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Lưu và gửi'));
  await tester.tap(find.text('Lưu và gửi'));
  await tester.pump();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'F01 conditional validation permits draft and requires complete submitted fields',
    (tester) async {
      final repo = FormRepository();
      await open(
        tester,
        repo,
        const TssaFormScreen(
          title: 'Academic profile',
          path: 'learners',
          initial: {'draft': false},
          fields: [
            TssaField(
              'grade',
              'Khối lớp',
              requiredWhenKey: 'draft',
              requiredWhenValue: false,
            ),
            TssaField('draft', 'Giữ nháp', kind: 'bool'),
          ],
        ),
      );
      await send(tester);
      expect(find.text('Nhập Khối lớp'), findsOneWidget);
      expect(repo.bodies, isEmpty);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await send(tester);
      await tester.pumpAndSettle();
      expect(repo.bodies.single['draft'], true);
      expect(find.text('Open'), findsOneWidget);
    },
  );
  testWidgets(
    'F02 no success until server acknowledgement and no double submission',
    (tester) async {
      final repo = FormRepository();
      final pending = Completer<TssaData>();
      repo.submit = () => pending.future;
      await open(
        tester,
        repo,
        const TssaFormScreen(
          title: 'Submit',
          path: 'requests',
          fields: [TssaField('goals', 'Mục tiêu', required: true)],
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Practice');
      await send(tester);
      expect(find.text('Chờ máy chủ xác nhận…'), findsOneWidget);
      expect(find.text('Máy chủ đã xác nhận lưu.'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repo.bodies.length, 1);
      pending.complete({'id': 'saved'});
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    },
  );
  testWidgets(
    'F03 failed retry retains key and changed payload gets a new key',
    (tester) async {
      final repo = FormRepository();
      repo.submit = () async => throw DioException(
        requestOptions: RequestOptions(path: 'requests'),
        type: DioExceptionType.connectionError,
      );
      await open(
        tester,
        repo,
        const TssaFormScreen(
          title: 'Retry',
          path: 'requests',
          fields: [TssaField('goals', 'Mục tiêu')],
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Practice');
      await send(tester);
      await tester.pumpAndSettle();
      expect(find.text('Máy chủ đã xác nhận lưu.'), findsNothing);
      await send(tester);
      await tester.pumpAndSettle();
      expect(repo.keys[0], repo.keys[1]);
      await tester.enterText(find.byType(TextFormField), 'Changed');
      await send(tester);
      await tester.pumpAndSettle();
      expect(repo.keys[2], isNot(repo.keys[1]));
    },
  );
  testWidgets('F04 explicit ordering is preserved in submitted shortlist', (
    tester,
  ) async {
    final repo = FormRepository();
    await open(
      tester,
      repo,
      const TssaFormScreen(
        title: 'Order',
        path: 'matches/r/decision',
        initial: {
          'tutorIds': ['a', 'b'],
        },
        fields: [
          TssaField(
            'tutorIds',
            'Ứng viên',
            kind: 'ordered',
            required: true,
            options: {'a': 'Tutor A', 'b': 'Tutor B'},
          ),
        ],
      ),
    );
    await tester.tap(find.byTooltip('Đưa lên trước').last);
    await tester.pump();
    await send(tester);
    await tester.pumpAndSettle();
    expect(repo.bodies.single['tutorIds'], ['b', 'a']);
  });
  testWidgets(
    'F05 autosave restores scoped draft and successful save removes it',
    (tester) async {
      final repo = FormRepository();
      await DraftStorage().write('alice', 'profile', {
        'values': {'goals': 'Restored'},
        'key': 'persistent-retry-key',
        'lastPayload': null,
      });
      await open(
        tester,
        repo,
        const TssaFormScreen(
          title: 'Draft',
          path: 'learners',
          owner: 'alice',
          draftId: 'profile',
          fields: [TssaField('goals', 'Mục tiêu')],
        ),
      );
      expect(find.text('Restored'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Edited');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(
        (await DraftStorage().read('alice', 'profile'))!['values']['goals'],
        'Edited',
      );
      await send(tester);
      await tester.pumpAndSettle();
      expect(await DraftStorage().read('alice', 'profile'), isNull);
      expect(repo.keys.single, 'persistent-retry-key');
    },
  );
  testWidgets('F06 dirty back asks before dropping input', (tester) async {
    final repo = FormRepository();
    await open(
      tester,
      repo,
      const TssaFormScreen(
        title: 'Dirty',
        path: 'requests',
        fields: [TssaField('goals', 'Mục tiêu')],
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Unsaved');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Rời biểu mẫu?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(repo.bodies, isEmpty);
  });
}
