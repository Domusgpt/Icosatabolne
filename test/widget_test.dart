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
    tester.binding.window.physicalSizeTestValue = const Size(2000, 2000);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AbaloneVib3App());

    // Verify that game title is present (Holographic appears in PlayerCard and VisualizerPanel)
    expect(find.text('Holographic'), findsNWidgets(2));
    expect(find.text('Quantum'), findsNWidgets(2));
  });
}
