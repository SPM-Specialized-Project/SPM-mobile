import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spm_mobile/app/app.dart';
import 'package:spm_mobile/core/security/draft_storage.dart';
import 'package:spm_mobile/core/security/token_storage.dart';
import 'package:spm_mobile/features/auth/application/auth_controller.dart';
import 'package:spm_mobile/features/tssa/data/tssa_repository.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final until = DateTime.now().add(const Duration(seconds: 30));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(until)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const learner = String.fromEnvironment('TEST_LEARNER_EMAIL');
  const tutor = String.fromEnvironment('TEST_TUTOR_EMAIL');
  const password = String.fromEnvironment('TEST_PASSWORD');
  const bookingId = String.fromEnvironment('TEST_BOOKING_ID');

  testWidgets(
    'Android TSSA: real secure storage, learner/tutor login, booking and agenda save',
    (tester) async {
      expect(learner, isNotEmpty);
      expect(tutor, isNotEmpty);
      expect(password, isNotEmpty);
      expect(
        const bool.fromEnvironment('TEST_ISOLATED_ANDROID'),
        true,
        reason:
            'Use scripts/run-android-validation.ps1 to preserve the main app.',
      );
      // Run only in the isolated validation application ID documented in run-android-validation.ps1.
      final drafts = DraftStorage();
      await drafts.write('synthetic-validation', 'platform-check', {
        'values': {'goals': 'Private synthetic draft'},
        'key': 'retry',
      });
      expect(
        (await drafts.read(
          'synthetic-validation',
          'platform-check',
        ))!['values']['goals'],
        'Private synthetic draft',
      );
      await drafts.remove('synthetic-validation', 'platform-check');
      expect(
        await drafts.read('synthetic-validation', 'platform-check'),
        isNull,
      );

      final container = ProviderContainer();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        container.dispose();
      });
      await container.read(tokenStorageProvider).clearAccessToken();
      await DraftStorage.clear();
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await waitFor(tester, find.text('Chào mừng trở lại'));
      await tester.enterText(find.byType(TextFormField).at(0), learner);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text('Đăng nhập'));
      await waitFor(tester, find.text('TSSA · Hồ sơ'));
      await waitFor(tester, find.text('Synthetic learner'));
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label),
        ['Hồ sơ', 'Yêu cầu', 'Lịch', 'Hỗ trợ'],
      );
      await tester.tap(find.byType(NavigationDestination).at(2));
      await waitFor(tester, find.textContaining('Đã xác nhận ·'));
      await tester.tap(find.textContaining('Đã xác nhận ·').first);
      await waitFor(tester, find.text('Synthetic video meeting'));
      expect(find.text('Mở phần hồ sơ còn consent'), findsNothing);

      // Logout while a child page is open must remove every protected route.
      await container.read(authControllerProvider.notifier).logout();
      await waitFor(tester, find.text('Chào mừng trở lại'));
      expect(find.text('Synthetic video meeting'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), tutor);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text('Đăng nhập'));
      await waitFor(tester, find.text('TSSA · Hồ sơ'));
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label),
        ['Hồ sơ', 'Ca được mời', 'Lịch', 'Hỗ trợ'],
      );
      await tester.tap(find.byType(NavigationDestination).at(2));
      await waitFor(tester, find.textContaining('Đã xác nhận ·'));
      await tester.tap(find.textContaining('Đã xác nhận ·').first);
      await waitFor(tester, find.text('Synthetic video meeting'));
      await tester.scrollUntilVisible(
        find.text('Chuẩn bị / ghi nhận buổi học'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Chuẩn bị / ghi nhận buổi học'));
      await waitFor(tester, find.byType(TextFormField));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Android integration agenda',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lưu và gửi'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Lưu và gửi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu và gửi'));
      await waitFor(tester, find.text('Máy chủ đã xác nhận lưu.'));
      final notes = await container
          .read(tssaRepositoryProvider)
          .read('bookings/$bookingId/notes');
      expect(
        tssaItems(
          notes,
        ).any((note) => note['agenda'] == 'Android integration agenda'),
        true,
      );
      expect(tester.takeException(), isNull);
      await container.read(authControllerProvider.notifier).logout();
      await waitFor(tester, find.text('Chào mừng trở lại'));
    },
  );
}
