import 'package:flutter_test/flutter_test.dart';
import 'package:icosatabolne/game/hex_grid.dart';
import 'package:icosatabolne/game/board_state.dart';

void main() {
  group('Hex Grid Logic', () {
    test('Hex addition', () {
      expect(Hex(1, 2) + Hex(2, 3), Hex(3, 5));
    });

    test('Hex distance', () {
      expect(Hex(0, 0).distanceTo(Hex(1, 1)), 2); // (1, 1) -> s = -2. (|1|+ |1| + |-2|)/2 = 2.
      // Wait, axial distance is usually max(abs(dq), abs(dr), abs(ds)).
      // My implementation used (abs(q)+abs(r)+abs(s))/2 which is equivalent to max(abs(q), abs(r), abs(s)) for a hex centered at 0.
      // But distanceTo does (this-other).length.
      // (0,0) to (1,1) -> diff is (1,1), s=-2. Length = (1+1+2)/2 = 2.
      // Wait, (1,1) is 2 steps away?
      // (0,0) -> (1,0) -> (1,1)?
      // Yes. (1,0) neighbor of (0,0). (1,1) neighbor of (1,0) (direction (0,1)).
      // So distance is 2. Correct.
    });

    test('Hex neighbor', () {
      expect(Hex(0, 0).neighbor(HexDirection.east), Hex(1, 0));
    });
  });

  group('Board State', () {
    test('Initial setup has correct count', () {
      final board = BoardState.initial();
      int holoCount = board.pieces.values.where((p) => p == Player.holographic).length;
      int quantCount = board.pieces.values.where((p) => p == Player.quantum).length;

      // 5 + 6 + 3 = 14
      expect(holoCount, 14);
      expect(quantCount, 14);
    });
  });
}
