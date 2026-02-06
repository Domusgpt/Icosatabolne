import 'hex_grid.dart';

enum Player {
  holographic, // Player 1
  quantum,     // Player 2
}

class BoardState {
  final Map<Hex, Player> pieces;
  final int radius;

  BoardState({Map<Hex, Player>? pieces, this.radius = 4})
      : pieces = pieces ?? {};

  BoardState.initial() : pieces = {}, radius = 4 {
    _setupStandardBoard();
  }

  void _setupStandardBoard() {
    // Standard Abalone setup for 5-sided board (radius 4)
    // 14 marbles per player.

    // Player 1 (Holographic) - Bottom side (positive r, generally)
    // But let's stick to a known layout.
    // If r increases downwards:
    // Row r=4: 5 marbles (q: 0 to -4 ? No, let's trace standard axial)

    // Let's use a symmetric setup.
    // Player 1:
    // Row 4 (5 cells): (0, 4), (-1, 4), (-2, 4), (-3, 4), (-4, 4) -- all filled?
    // Row 3 (6 cells): (-4, 3) to (1, 3) -- 6 filled
    // Row 2 (7 cells): (-2, 2) to (0, 2) -- 3 filled in center?
    // Standard Abalone:
    // 5 balls on the back row.
    // 6 balls on the second row.
    // 3 balls on the third row (centered).

    // Player Holographic (Black, bottom):
    // r=4: q=-4,-3,-2,-1,0 (5 balls)
    // r=3: q=-4,-3,-2,-1,0,1 (6 balls)
    // r=2: q=-2,-1,0 (3 balls)

    for (int q = -4; q <= 0; q++) _add(Hex(q, 4), Player.holographic);
    for (int q = -4; q <= 1; q++) _add(Hex(q, 3), Player.holographic);
    for (int q = -2; q <= 0; q++) _add(Hex(q, 2), Player.holographic);

    // Player Quantum (White, top):
    // r=-4: q=0,1,2,3,4 (5 balls)
    // r=-3: q=-1,0,1,2,3,4 (6 balls)
    // r=-2: q=0,1,2 (3 balls)

    for (int q = 0; q <= 4; q++) _add(Hex(q, -4), Player.quantum);
    for (int q = -1; q <= 4; q++) _add(Hex(q, -3), Player.quantum);
    for (int q = 0; q <= 2; q++) _add(Hex(q, -2), Player.quantum);
  }

  void _add(Hex hex, Player player) {
    pieces[hex] = player;
  }

  Player? getPiece(Hex hex) => pieces[hex];

  bool isValidHex(Hex hex) {
    return hex.length <= radius;
  }

  BoardState copy() {
    return BoardState(pieces: Map.from(pieces), radius: radius);
  }
}
