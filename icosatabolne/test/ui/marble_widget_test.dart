import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/ui/marble_widget.dart';
import 'package:icosatabolne/visuals/vib3_adapter.dart';

void main() {
  testWidgets('MarbleWidget renders Vib3Adapter', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MarbleWidget(
          player: Player.holographic,
          size: 50,
          animate: false,
        ),
      ),
    ));

    await tester.pump(); // Start animation (Adapter animate=true default)
    debugDefaultTargetPlatformOverride = null;

    expect(find.byType(Vib3Adapter), findsOneWidget);

    // Check decoration (circle)
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
  });
}
