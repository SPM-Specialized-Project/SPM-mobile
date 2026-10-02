// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spm_mobile/app/app.dart';
import 'package:spm_mobile/core/security/token_storage.dart';
import 'package:spm_mobile/features/backend_status/application/backend_health_provider.dart';
import 'package:spm_mobile/features/backend_status/data/backend_health.dart';
import 'package:spm_mobile/features/component_catalog/presentation/mobile_home_screen.dart';

import 'support/fake_token_storage.dart';

void main() {
  testWidgets('opens the branded login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(FakeTokenStorage())],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('HCMUT SSO'), findsOneWidget);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('component showcase still renders independently', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MobileHomeScreen())),
    );

    expect(find.text('Tutor Support System'), findsOneWidget);
    expect(find.text('Computer Network'), findsOneWidget);
    expect(find.text('Database System'), findsOneWidget);
    expect(find.text('Operating System'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Thư viện'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Thư viện'), findsOneWidget);
  });

  testWidgets('backend health screen remains reachable from the showcase', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendHealthProvider.overrideWith(
            (ref) async =>
                const BackendHealth(ok: true, service: 'spm-backend'),
          ),
        ],
        child: const MaterialApp(home: MobileHomeScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Kiểm tra backend'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối thành công'), findsOneWidget);
    expect(find.text('Service: spm-backend'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
