import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/game/game_events.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/game/hex_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameController', () {
    late GameController controller;

    setUp(() {
      controller = GameController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is correct', () {
      expect(controller.currentTurn, Player.holographic);
      expect(controller.turnCount, 1);
      expect(controller.capturedMarbles[Player.holographic], 0);
      expect(controller.capturedMarbles[Player.quantum], 0);
      expect(controller.isGameOver, false);
    });

    test('Emits MoveEvent on valid move', () async {
      // Find a valid move for Holographic (Black)
      // Standard setup: Black is at bottom (q,-r?).
      // Let's find a black marble.
      Hex? blackMarble;
      controller.board.pieces.forEach((hex, p) {
        if (p == Player.holographic) blackMarble = hex;
      });

      expect(blackMarble, isNotNull);

      // Try to move it to an empty neighbor
      HexDirection dir = HexDirection.northEast; // Arbitrary
      // We need to find a move that is valid (space empty)
      // Actually, standard setup is packed. We might need to select the front line.
      // But let's just create a custom board state if needed, or search.

      // Let's assume standard board.
      // Black occupies bottom rows.
      // Moving a leading edge marble forward should work.

      // Instead of guessing, let's mock the board state if possible, or just trust the rules logic (tested elsewhere)
      // and just verify event emission.

      // Let's reset the board to a simple state if we could, but GameController uses BoardState.initial().
      // Let's rely on finding a valid move.
      // E.g. (0, 4) is black?
      // Radius 4.
      // Let's pick a specific known marble.
      // (0, 4) ->
      // Hex(0, 4) is likely black.

      // Let's just listen to the stream.
      bool eventReceived = false;
      controller.events.listen((event) {
        if (event is MoveEvent) {
          eventReceived = true;
          expect(event.player, Player.holographic);
        }
      });

      // We need to find a VALID move.
      // Let's cheat: We rely on the fact that the initial board has valid moves.
      // We'll iterate all marbles and directions until one returns true.

      bool moved = false;
      for (var entry in controller.board.pieces.entries) {
        if (entry.value == Player.holographic) {
          for (var d in HexDirection.values) {
            if (controller.makeMove([entry.key], d)) {
              moved = true;
              break;
            }
          }
        }
        if (moved) break;
      }

      expect(moved, isTrue, reason: "Should find at least one valid move on initial board");

      // Wait for stream
      await Future.delayed(Duration.zero);
      expect(eventReceived, isTrue);
    });
  });
}
