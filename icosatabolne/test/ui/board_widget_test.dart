import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/ui/board_widget.dart';
import 'package:icosatabolne/ui/marble_widget.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('BoardWidget renders marbles', (WidgetTester tester) async {
    final controller = GameController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const BoardWidget(size: 300, animateMarbles: false),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Verify marbles are rendered
    // Initial setup has 28 marbles.
    expect(find.byType(MarbleWidget), findsNWidgets(28));

    // Verify custom paint (background)
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('BoardWidget handles selection', (WidgetTester tester) async {
    final controller = GameController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const BoardWidget(size: 300, animateMarbles: false),
        ),
      ),
    ));

    // Tap on a marble
    await tester.tap(find.byType(MarbleWidget).first);
    await tester.pump();

    final selectedMarbles = tester.widgetList<MarbleWidget>(find.byType(MarbleWidget))
        .where((w) => w.isSelected);

    expect(selectedMarbles.length, 1);
  });
}
