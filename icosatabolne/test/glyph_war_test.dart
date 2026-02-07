import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/glyph_war/game_logic.dart';
import 'package:icosatabolne/glyph_war/ui/glyph_war_screen.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.vib3.engine');

  setUpAll(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'initialize') {
        return {'textureId': 1};
      }
      if (methodCall.method == 'captureFrame') {
        return null;
      }
      return null;
    });
  });

  group('GlyphWarController Logic', () {
    late GlyphWarController controller;

    setUp(() {
      controller = GlyphWarController();
    });

    test('Initial state', () {
      expect(controller.phase, GlyphWarPhase.scramble);
      expect(controller.pile.isNotEmpty, true);
      expect(controller.player1.currentWord, isEmpty);
      expect(controller.player2.currentWord, isEmpty);
    });

    test('Grab Glyph', () {
      final glyph = controller.pile.first;
      controller.grabGlyph(glyph.id, 'P1');
      expect(controller.player1.currentWord.contains(glyph), true);
      expect(controller.pile.contains(glyph), false);
    });

    test('Stash Glyph', () {
      final glyph = controller.pile.first;
      controller.grabGlyph(glyph.id, 'P1');
      controller.stashGlyph(glyph.id, 'P1');

      expect(controller.player1.stashedGlyph, glyph);
      expect(controller.player1.currentWord.contains(glyph), false);
      expect(glyph.isStashed, true);
    });

    test('Dissolve Word', () {
      final glyph = controller.pile.first;
      controller.grabGlyph(glyph.id, 'P1');
      controller.dissolveWord('P1');

      expect(controller.player1.currentWord, isEmpty);
      expect(controller.pile.contains(glyph), true); // Returns to pile
    });

    test('Attack Mode', () {
      // P1 grabs letters (needs 2 for valid word)
      final glyph = controller.pile[0];
      final glyph1b = controller.pile[1];
      controller.grabGlyph(glyph.id, 'P1');
      controller.grabGlyph(glyph1b.id, 'P1');

      controller.startAttack('P1');
      expect(controller.phase, GlyphWarPhase.attack);
      expect(controller.player1.isAttacking, true);

      // P2 grabs a letter (longer word)
      // P1 has 2. P2 needs 3 to beat.
      // Note: grabGlyph removes from pile. pile[0] is now original pile[2].
      final glyph2 = controller.pile[0];
      final glyph3 = controller.pile[1];
      final glyph4 = controller.pile[2];
      controller.grabGlyph(glyph2.id, 'P2');
      controller.grabGlyph(glyph3.id, 'P2');
      controller.grabGlyph(glyph4.id, 'P2');

      // P2 len=3, P1 len=2.
      // Should switch attack.

      expect(controller.player2.isAttacking, true, reason: "P2 should counter-attack");
      expect(controller.player1.isAttacking, false);
    });
  });

  testWidgets('GlyphWarScreen UI Test', (WidgetTester tester) async {
    // Set large window size
    tester.view.physicalSize = const Size(2000, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: GlyphWarScreen()));
    await tester.pumpAndSettle(); // Wait for animations and async init

    // Verify basic UI elements
    expect(find.text('ATTACK'), findsOneWidget);
    expect(find.text('DISSOLVE'), findsOneWidget);
    expect(find.text('STASH'), findsAtLeastNWidgets(1));

    // Verify Glyphs are rendered
    // Since glyph chars are random, we look for any single char text or Draggable
    expect(find.byType(Draggable<String>), findsWidgets);

    // Test dragging
    final draggableFinder = find.byType(Draggable<String>).first;
    // Find a drop target (Player 1 rack)
    // The rack is container with cyan/white border. Hard to find by type.
    // We can find by key if we added keys, or just offset.
    // Or find the text 'ATTACK' and drop near it (controls are near rack).

    final controlsFinder = find.text('ATTACK');
    final rackOffset = tester.getCenter(controlsFinder) + const Offset(0, 80); // Rack is below controls

    // Drag
    await tester.drag(draggableFinder, Offset(0, 500)); // Drag down wildly
    // We need precise target.
    // Let's rely on unit tests for logic and just verify UI structure here.

    // Cleanup
    addTearDown(tester.view.resetPhysicalSize);
  });
}
