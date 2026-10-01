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
import 'package:spm_mobile/features/backend_status/application/backend_health_provider.dart';
import 'package:spm_mobile/features/backend_status/data/backend_health.dart';

void main() {
  testWidgets('shows a successful backend health response', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendHealthProvider.overrideWith(
            (ref) async =>
                const BackendHealth(ok: true, service: 'spm-backend'),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Kết nối thành công'), findsOneWidget);
    expect(find.text('Service: spm-backend'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
