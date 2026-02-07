import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game/hex_grid.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/game/rules.dart';

void main() {
  group('Rules Logic', () {
    test('Valid inline move into empty space', () {
      final board = BoardState(pieces: {
        Hex(0, 0): Player.holographic,
        Hex(1, 0): Player.holographic,
      });

      final selection = [Hex(0, 0), Hex(1, 0)];
      final result = Rules.validateMove(board, selection, HexDirection.east);

      expect(result.isValid, isTrue);
      expect(result.type, MoveType.inline);
      expect(result.movingMarbles.length, 2);
      expect(result.pushedMarbles, isEmpty);
    });

    test('Valid broadside move', () {
      final board = BoardState(pieces: {
        Hex(0, 0): Player.holographic,
        Hex(1, 0): Player.holographic,
      });

      final selection = [Hex(0, 0), Hex(1, 0)];
      final result = Rules.validateMove(board, selection, HexDirection.southEast);
      // Direction SouthEast (0, 1). Neighbors: (0, 1) and (1, 1). Both empty.

      expect(result.isValid, isTrue);
      expect(result.type, MoveType.broadside);
    });

    test('Valid sumito push (2 vs 1)', () {
      final board = BoardState(pieces: {
        Hex(0, 0): Player.holographic,
        Hex(1, 0): Player.holographic,
        Hex(2, 0): Player.quantum, // Opponent
      });

      final selection = [Hex(0, 0), Hex(1, 0)];
      // Push East. (1, 0) is head. Hits (2, 0). (3, 0) is empty.
      // Wait, head logic.
      // Head is selection marble whose neighbor is NOT in selection.
      // (0,0) neighbor east is (1,0) (in selection).
      // (1,0) neighbor east is (2,0) (NOT in selection).
      // So head is (1,0).

      final result = Rules.validateMove(board, selection, HexDirection.east);

      expect(result.isValid, isTrue);
      expect(result.type, MoveType.inline);
      expect(result.pushedMarbles.length, 1);
      expect(result.pushedMarbles.first, Hex(2, 0));
    });

    test('Invalid sumito push (equal strength 2 vs 2)', () {
      final board = BoardState(pieces: {
        Hex(0, 0): Player.holographic,
        Hex(1, 0): Player.holographic,
        Hex(2, 0): Player.quantum,
        Hex(3, 0): Player.quantum,
      });

      final selection = [Hex(0, 0), Hex(1, 0)];
      final result = Rules.validateMove(board, selection, HexDirection.east);

      expect(result.isValid, isFalse);
    });
  });
}
