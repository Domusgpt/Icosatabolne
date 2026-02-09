// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:icosatabolne/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set a large surface size to minimize overflow in test environment
    tester.view.physicalSize = const Size(2000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AbaloneVib3App());

    // Verify that game title is present in the new HUD (All Caps)
    expect(find.text('HOLOGRAPHIC'), findsOneWidget);
    expect(find.text('QUANTUM'), findsOneWidget);

    // Verify that visualizer parameters are displayed in the footer
    expect(find.text('CHAOS'), findsOneWidget);
    expect(find.text('DENSITY'), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
  });
}
