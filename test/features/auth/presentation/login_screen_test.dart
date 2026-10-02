import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spm_mobile/app/app.dart';
import 'package:spm_mobile/core/security/token_storage.dart';

import '../../../support/fake_token_storage.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(FakeTokenStorage())],
      child: const MyApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  testWidgets('shows brand, welcome text, fields, and login button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(find.text('HCMUT SSO'), findsOneWidget);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password visibility control reveals the password field', (
    tester,
  ) async {
    await _pumpApp(tester);

    final passwordField = find.ancestor(
      of: find.text('Mật khẩu'),
      matching: find.byType(TextFormField),
    );
    final editableText = find.descendant(
      of: passwordField,
      matching: find.byType(EditableText),
    );

    expect(tester.widget<EditableText>(editableText).obscureText, isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<EditableText>(editableText).obscureText, isFalse);
  });

  testWidgets('validates empty email and password before calling the API', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
