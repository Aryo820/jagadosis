// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen displays the app name 'JagaDosis'.
    expect(find.text('JagaDosis'), findsOneWidget);

    // Let the timer run to navigate and clean up the test state.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
