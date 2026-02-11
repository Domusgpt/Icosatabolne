import 'dart:math';

enum PlayerSide { holographic, quantum }

enum MarbleState { empty, holographic, quantum }

enum Direction {
  ne, // North East
  e,  // East
  se, // South East
  sw, // South West
  w,  // West
  nw  // North West
}

class HexCoordinate {
  final int x;
  final int y;
  final int z;

  const HexCoordinate(this.x, this.y, this.z) : assert(x + y + z == 0);

  @override
  bool operator ==(Object other) =>
      other is HexCoordinate && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => '($x, $y, $z)';

  HexCoordinate operator +(HexCoordinate other) =>
      HexCoordinate(x + other.x, y + other.y, z + other.z);

  HexCoordinate neighbor(Direction dir) {
    switch (dir) {
      case Direction.ne: return this + const HexCoordinate(1, 0, -1);
      case Direction.e:  return this + const HexCoordinate(1, -1, 0);
      case Direction.se: return this + const HexCoordinate(0, -1, 1);
      case Direction.sw: return this + const HexCoordinate(-1, 0, 1);
      case Direction.w:  return this + const HexCoordinate(-1, 1, 0);
      case Direction.nw: return this + const HexCoordinate(0, 1, -1);
    }
  }

  // Helper to find direction between two adjacent coords
  Direction? directionTo(HexCoordinate other) {
    final dx = other.x - x;
    final dy = other.y - y;
    final dz = other.z - z;

    if (dx == 1 && dy == 0 && dz == -1) return Direction.ne;
    if (dx == 1 && dy == -1 && dz == 0) return Direction.e;
    if (dx == 0 && dy == -1 && dz == 1) return Direction.se;
    if (dx == -1 && dy == 0 && dz == 1) return Direction.sw;
    if (dx == -1 && dy == 1 && dz == 0) return Direction.w;
    if (dx == 0 && dy == 1 && dz == -1) return Direction.nw;
    return null;
  }
}

class Board {
  final Map<HexCoordinate, MarbleState> _grid = {};

  // Abalone standard board radius is 4 (coordinates -4 to 4)
  static const int radius = 4;

  int holoCaptured = 0;
  int quantumCaptured = 0;

  Board() {
    _initializeBoard();
  }

  // Copy constructor
  Board.from(Board other) {
    _grid.addAll(other._grid);
    holoCaptured = other.holoCaptured;
    quantumCaptured = other.quantumCaptured;
  }

  void _initializeBoard() {
    // Generate empty board
    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        int z = -x - y;
        if (z.abs() <= radius) {
          _grid[HexCoordinate(x, y, z)] = MarbleState.empty;
        }
      }
    }

    // Standard Setup
    // Implementing standard layout logic based on row indices logic in main.dart
    // Rows 0,1 (top/bottom depending on perspective) are filled.
    // Let's assume standard Abalone setup where Black (Holo) is at bottom (high z or high y?)
    // Using simple iteration to match visualizer logic.

    for (int r = 0; r < 9; r++) {
      int z = r - 4; // -4 to 4
      int count = 9 - z.abs();
      int firstX = max(-4, -4 - z);

      for (int c = 0; c < count; c++) {
        int x = firstX + c;
        int y = -x - z;
        var coord = HexCoordinate(x, y, z);

        // Setup pieces
        // Top 2 rows (z = -4, -3) -> Black/Holographic
        // Top center 3 of row 2 (z = -2) -> Black/Holographic

        // Bottom 2 rows (z = 4, 3) -> White/Quantum
        // Bottom center 3 of row 6 (z = 2) -> White/Quantum

        if (z <= -3) {
          _grid[coord] = MarbleState.holographic;
        } else if (z == -2 && c >= 2 && c <= 4) {
             _grid[coord] = MarbleState.holographic;
        } else if (z >= 3) {
          _grid[coord] = MarbleState.quantum;
        } else if (z == 2 && c >= 2 && c <= 4) {
             _grid[coord] = MarbleState.quantum;
        } else {
          _grid[coord] = MarbleState.empty;
        }
      }
    }
  }

  MarbleState? get(HexCoordinate c) => _grid[c];

  bool isValid(HexCoordinate c) => _grid.containsKey(c);

  void set(HexCoordinate c, MarbleState s) {
    if (isValid(c)) {
      _grid[c] = s;
    }
  }

  // Executes a move. Assumes the move has been validated by MoveValidator.
  void executeMove(List<HexCoordinate> selection, Direction dir) {
    // Check if inline
    bool isInline = false;
    if (selection.length > 1) {
       var d = selection[0].directionTo(selection[1]);
       if (d != null && (d == dir || (d.index - dir.index).abs() == 3)) {
         isInline = true;
       }
    } else {
      isInline = true; // Single marble is always inline move logic essentially
    }

    if (isInline) {
      _executeInlineMove(selection, dir);
    } else {
      _executeBroadsideMove(selection, dir);
    }
  }

  void _executeBroadsideMove(List<HexCoordinate> selection, Direction dir) {
    Map<HexCoordinate, MarbleState> newStates = {};
    for (var c in selection) {
      newStates[c.neighbor(dir)] = _grid[c]!;
      _grid[c] = MarbleState.empty;
    }
    _grid.addAll(newStates);
  }

  void _executeInlineMove(List<HexCoordinate> selection, Direction dir) {
    // Find the leading marble (tip)
    HexCoordinate? tip;
    for (var c in selection) {
      if (!selection.contains(c.neighbor(dir))) {
        tip = c;
        break;
      }
    }

    if (tip == null) return; // Should not happen

    // Identify chain to push
    var current = tip.neighbor(dir);
    List<HexCoordinate> toPush = [];

    while (isValid(current) && _grid[current] != MarbleState.empty) {
      toPush.add(current);
      current = current.neighbor(dir);
    }

    // Check if pushing off board
    bool pushOff = !isValid(current);

    // Ordered list of all marbles moving: [furthest pushed, ..., closest pushed, tip, ..., tail]
    List<HexCoordinate> movingChain = [];
    if (toPush.isNotEmpty) {
      movingChain.addAll(toPush.reversed);
    }

    // Add selection sorted from tip to tail
    List<HexCoordinate> sortedSelection = [];
    var currSel = tip;
    while (selection.contains(currSel)) {
      sortedSelection.add(currSel);
      currSel = currSel.neighbor(_opposite(dir));
    }
    movingChain.addAll(sortedSelection);

    // Execute move
    if (pushOff && toPush.isNotEmpty) {
      // The furthest marble falls off
      var fallen = movingChain.first; // Last pushed marble is first in movingChain
      var state = _grid[fallen]!;
      if (state == MarbleState.holographic) holoCaptured++;
      if (state == MarbleState.quantum) quantumCaptured++;

      _grid[fallen] = MarbleState.empty; // Remove from grid (conceptually)

      // Move the rest of the chain
      for (int i = 1; i < movingChain.length; i++) {
        var src = movingChain[i];
        var dst = src.neighbor(dir);
        _grid[dst] = _grid[src]!;
      }
      // Clear the tail
      _grid[movingChain.last] = MarbleState.empty;

    } else {
      // Normal move (or push into empty space)
      // Move everyone one step forward starting from front
      for (var src in movingChain) {
        var dst = src.neighbor(dir);
        if (isValid(dst)) {
          _grid[dst] = _grid[src]!;
        }
      }
      // Clear the tail
      _grid[movingChain.last] = MarbleState.empty;
    }
  }

  Direction _opposite(Direction d) {
    int idx = (d.index + 3) % 6;
    return Direction.values[idx];
  }
}

class MoveValidator {
  final Board board;

  MoveValidator(this.board);

  bool validateSelection(List<HexCoordinate> selection, PlayerSide player) {
    if (selection.isEmpty || selection.length > 3) return false;

    MarbleState playerMarble = player == PlayerSide.holographic
        ? MarbleState.holographic
        : MarbleState.quantum;

    // Check ownership
    for (var c in selection) {
      if (board.get(c) != playerMarble) return false;
    }

    if (selection.length == 1) return true;

    // Check linearity and adjacency
    return _areInline(selection);
  }

  bool _areInline(List<HexCoordinate> selection) {
    if (selection.length <= 1) return true;

    if (selection.length == 2) {
      return selection[0].directionTo(selection[1]) != null;
    }

    if (selection.length == 3) {
      // Check if there exists a middle element adjacent to other two
      for (var mid in selection) {
        var others = selection.where((c) => c != mid).toList();
        if (others.length != 2) continue;
        var d1 = mid.directionTo(others[0]);
        var d2 = mid.directionTo(others[1]);
        if (d1 != null && d2 != null && _isOpposite(d1, d2)) {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  bool _isOpposite(Direction d1, Direction d2) {
    return (d1.index - d2.index).abs() == 3;
  }

  bool validateMove(List<HexCoordinate> selection, Direction dir, PlayerSide player) {
    if (!validateSelection(selection, player)) return false;

    if (_isInlineMove(selection, dir)) {
      return _validateInlineMove(selection, dir, player);
    } else {
      return _validateBroadsideMove(selection, dir);
    }
  }

  bool _isInlineMove(List<HexCoordinate> selection, Direction dir) {
    if (selection.length == 1) return true;
    // If adjacent, lineDir is not null. But validateSelection ensures adjacency/linearity.
    // For 3 items, 0 and 1 might not be adjacent if sorted weirdly, but usually selection comes from UI in some order.
    // Assuming selection[0] and [1] are adjacent or we find direction from structure.

    // Robust check: find direction of the line formed by selection
    Direction? validLineDir;
    if (selection.length == 2) {
       validLineDir = selection[0].directionTo(selection[1]);
    } else {
       // Find middle
       for (var mid in selection) {
         var others = selection.where((c) => c != mid).toList();
         if (others.length == 2 && mid.directionTo(others[0]) != null) {
            validLineDir = mid.directionTo(others[0]);
            break;
         }
       }
    }

    if (validLineDir == null) return false;

    return validLineDir == dir || _isOpposite(validLineDir, dir);
  }

  bool _validateBroadsideMove(List<HexCoordinate> selection, Direction dir) {
    for (var c in selection) {
      var dest = c.neighbor(dir);
      if (!board.isValid(dest)) return false;
      if (board.get(dest) != MarbleState.empty) return false;
    }
    return true;
  }

  bool _validateInlineMove(List<HexCoordinate> selection, Direction dir, PlayerSide player) {
    HexCoordinate? tip;
    for (var c in selection) {
      if (!selection.contains(c.neighbor(dir))) {
        tip = c;
        break;
      }
    }

    if (tip == null) return false;

    var current = tip.neighbor(dir);
    int pushStrength = selection.length;
    int opponentCount = 0;

    MarbleState opponentMarble = player == PlayerSide.holographic
        ? MarbleState.quantum
        : MarbleState.holographic;

    while (true) {
      if (!board.isValid(current)) {
        if (opponentCount > 0) {
           return pushStrength > opponentCount;
        }
        return false;
      }

      var state = board.get(current);
      if (state == MarbleState.empty) {
        return pushStrength > opponentCount;
      } else if (state == opponentMarble) {
        opponentCount++;
        if (opponentCount >= pushStrength) {
          return false;
        }
      } else {
        return false;
      }

      current = current.neighbor(dir);
    }
  }
}
