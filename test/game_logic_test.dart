import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game_logic.dart';

void main() {
  group('HexCoordinate', () {
    test('neighbor returns correct coordinate', () {
      final center = HexCoordinate(0, 0, 0);
      expect(center.neighbor(Direction.ne), HexCoordinate(1, 0, -1));
      expect(center.neighbor(Direction.e), HexCoordinate(1, -1, 0));
    });

    test('directionTo returns correct direction', () {
      final center = HexCoordinate(0, 0, 0);
      expect(center.directionTo(HexCoordinate(1, 0, -1)), Direction.ne);
      expect(center.directionTo(HexCoordinate(1, -1, 0)), Direction.e);
    });
  });

  // Note: Board setup test would require Board implementation to be finished
  // but we can check if it initializes.
  group('Board', () {
    test('initializes correctly', () {
      final board = Board();
      // Check center
      expect(board.get(HexCoordinate(0, 0, 0)), MarbleState.empty);

      // Check limits
      expect(board.isValid(HexCoordinate(4, -4, 0)), true);
      expect(board.isValid(HexCoordinate(5, -5, 0)), false);
    });

    test('executes inline move correctly', () {
      final board = Board();
      // Setup a custom scenario
      // Clear board
      // Use internal grid access if possible, or use set

      // Let's use 0,0,0
      var center = HexCoordinate(0, 0, 0);
      var neighbor = HexCoordinate(1, -1, 0); // E

      board.set(center, MarbleState.holographic);
      board.set(neighbor, MarbleState.empty);

      board.executeMove([center], Direction.e);

      expect(board.get(center), MarbleState.empty);
      expect(board.get(neighbor), MarbleState.holographic);
    });

    test('executes broadside move correctly', () {
      final board = Board();
      var c1 = HexCoordinate(0, 0, 0);
      var c2 = HexCoordinate(1, -1, 0); // E
      // Move NE
      var d1 = HexCoordinate(1, 0, -1); // NE from c1
      var d2 = HexCoordinate(2, -1, -1); // NE from c2

      board.set(c1, MarbleState.holographic);
      board.set(c2, MarbleState.holographic);
      board.set(d1, MarbleState.empty);
      board.set(d2, MarbleState.empty);

      board.executeMove([c1, c2], Direction.ne);

      expect(board.get(c1), MarbleState.empty);
      expect(board.get(c2), MarbleState.empty);
      expect(board.get(d1), MarbleState.holographic);
      expect(board.get(d2), MarbleState.holographic);
    });

    test('executes push correctly', () {
      final board = Board();
      // Holographic (0,0,0), (1,-1,0) pushes Quantum (2,-2,0) East
      var h1 = HexCoordinate(0, 0, 0);
      var h2 = HexCoordinate(1, -1, 0);
      var q1 = HexCoordinate(2, -2, 0);
      var empty = HexCoordinate(3, -3, 0);

      board.set(h1, MarbleState.holographic);
      board.set(h2, MarbleState.holographic);
      board.set(q1, MarbleState.quantum);
      board.set(empty, MarbleState.empty);

      // Move East
      board.executeMove([h1, h2], Direction.e);

      expect(board.get(h1), MarbleState.empty);
      expect(board.get(h2), MarbleState.holographic);
      expect(board.get(q1), MarbleState.holographic);
      expect(board.get(empty), MarbleState.quantum);
    });

    test('captures single piece pushed off', () {
      final board = Board();
      // Reset captured count
      board.quantumCaptured = 0;

      // Setup near edge. (4,-4,0) is edge.
      // H at (3,-3,0) pushes Q at (4,-4,0) East.
      var h1 = HexCoordinate(3, -3, 0);
      var q1 = HexCoordinate(4, -4, 0);

      board.set(h1, MarbleState.holographic);
      board.set(q1, MarbleState.quantum);

      board.executeMove([h1], Direction.e);

      expect(board.get(h1), MarbleState.empty); // Moved
      expect(board.get(q1), MarbleState.holographic); // Taken by H
      expect(board.quantumCaptured, 1);
    });
  });
}
