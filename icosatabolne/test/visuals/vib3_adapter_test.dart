import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/visuals/vib3_adapter.dart';
import 'package:icosatabolne/visuals/fallback_painter.dart';
import 'package:vib3_flutter/vib3_flutter.dart';

void main() {
  testWidgets('Vib3Adapter renders fallback on non-mobile', (WidgetTester tester) async {
    // In test environment (Linux/VM), it should fallback.

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Vib3Adapter(
          config: Vib3Config(system: 'holographic'),
          width: 100,
          height: 100,
          animate: false,
        ),
      ),
    ));

    // Pump to let async init run
    await tester.pumpAndSettle();

    // Verify CustomPaint is found (FallbackPainter)
    expect(find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is FallbackPainter), findsOneWidget);

    // Verify NO Texture widget (which Vib3View uses)
    // Actually Vib3View uses Texture, but since engine is null/uninitialized, it won't be in tree?
    // My code returns Container or SizedBox(child: Vib3View).
    // If fallback, it returns AnimatedBuilder -> CustomPaint.
    // So if CustomPaint is found, fallback is active.
  });
}
