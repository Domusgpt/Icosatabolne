import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/ui/game_screen.dart';
import 'package:icosatabolne/ui/board_widget.dart';

void main() {
  testWidgets('GameScreen renders components', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GameScreen(),
    ));

    // Pump to settle initial animations
    await tester.pump(const Duration(seconds: 1));

    // Verify BoardWidget is present
    expect(find.byType(BoardWidget), findsOneWidget);

    // Verify Score/Header text
    expect(find.text('ICOSATABOLNE'), findsOneWidget);
    expect(find.text('HOLO'), findsOneWidget);
    expect(find.text('QUANTUM'), findsOneWidget);

    // Verify Turn indicator
    expect(find.textContaining('TURN:'), findsOneWidget);
  });
}
