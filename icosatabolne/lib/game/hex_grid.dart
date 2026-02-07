import 'dart:math';

enum HexDirection {
  east,
  southEast,
  southWest,
  west,
  northWest,
  northEast;

  HexDirection get opposite {
    return HexDirection.values[(index + 3) % 6];
  }
}

class Hex {
  final int q;
  final int r;

  const Hex(this.q, this.r);

  int get s => -q - r;

  @override
  bool operator ==(Object other) =>
      other is Hex && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Hex($q, $r)';

  Hex operator +(Hex other) => Hex(q + other.q, r + other.r);
  Hex operator -(Hex other) => Hex(q - other.q, r - other.r);
  Hex operator *(int scalar) => Hex(q * scalar, r * scalar);

  int get length => (q.abs() + r.abs() + s.abs()) ~/ 2;

  int distanceTo(Hex other) => (this - other).length;

  static const List<Hex> directions = [
    Hex(1, 0), Hex(0, 1), Hex(-1, 1),
    Hex(-1, 0), Hex(0, -1), Hex(1, -1)
  ];

  Hex neighbor(HexDirection direction) {
    return this + directions[direction.index];
  }

  static HexDirection? getDirection(Hex from, Hex to) {
    final diff = to - from;
    if (diff.length == 0) return null;
    // Normalize roughly to find direction
    // This is simple for adjacent hexes
    for (int i = 0; i < directions.length; i++) {
      if (directions[i] == diff) return HexDirection.values[i];
    }
    // For non-adjacent, finding the "line" direction
    // Check if on a line
    if (diff.q == 0 || diff.r == 0 || diff.s == 0) {
        // It is on a line. Let's find which one.
        // If q is positive and r is 0 -> east (1, 0)
        // If q is positive and s is 0 (r = -q) -> northEast (1, -1)
        // Wait, logic needs to match directions list:
        // 0: (1, 0) East
        // 1: (0, 1) SouthEast
        // 2: (-1, 1) SouthWest
        // 3: (-1, 0) West
        // 4: (0, -1) NorthWest
        // 5: (1, -1) NorthEast

        if (diff.q > 0 && diff.r == 0) return HexDirection.east;
        if (diff.q == 0 && diff.r > 0) return HexDirection.southEast;
        if (diff.r > 0 && diff.s == 0) return HexDirection.southWest; // r > 0, q < 0 -> (-1, 1)
        if (diff.q < 0 && diff.r == 0) return HexDirection.west;
        if (diff.q == 0 && diff.r < 0) return HexDirection.northWest;
        if (diff.r < 0 && diff.s == 0) return HexDirection.northEast; // r < 0, q > 0 -> (1, -1)
    }

    return null;
  }
}
