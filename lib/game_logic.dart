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

  // Abalone standard board radius is 5 (coordinates -4 to 4)
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

    // Standard Belgian Daisy setup or Standard Setup
    // Implementing Standard Setup:
    // Black (Holographic): Bottom 2 rows + center 3 of 3rd row
    // White (Quantum): Top 2 rows + center 3 of 3rd row from top

    // Actually, let's look at the implementation in main.dart:
    // row 0, 1: holographic
    // row 7, 8: quantum
    // rowCounts = [5, 6, 7, 8, 9, 8, 7, 6, 5];

    // Mapping 2D rows to Hex Coordinates
    // Let's use the same layout as main.dart visualizer for consistency.
    // Row 0 is top? Wait, main.dart says row < 2 is holographic.
    // If row 0 is top, then holographic is at top?
    // main.dart:
    // row 0 (5 cells): holographic
    // row 1 (6 cells): holographic
    // row 7 (6 cells): quantum
    // row 8 (5 cells): quantum

    // In standard Abalone, Black (usually plays first) starts at bottom (User view).
    // Let's assume standard setup.

    // Let's implement setup based on coordinates.
    // Using axial coordinates (q, r) -> (x, z)
    // q = x, r = z, y = -x-z

    // Fill Holographic (Bottom)
    // Rows where z is high (positive)
    // Or we can just iterate and fill based on pattern.

    // Let's use a standard filling.
    // Bottom 5 (z=4, y ranges from -4 to 0, x ranges from 0 to 4? no)

    // Let's just use the loop logic from main.dart but adapted to HexCoordinate.
    // rowCounts = [5, 6, 7, 8, 9, 8, 7, 6, 5]
    // center row is index 4 (9 cells).
    // let's map row index `r` (0..8) and col index `c` to HexCoordinate.
    // center is (0,0,0).
    // row 4 is z=0 (horizontal center line). No, horizontal rows are usually y=const or z=const.
    // Let's say z is constant for horizontal rows.
    // z ranges from -4 to 4.
    // row 0: z = -4. Length 5. x ranges from 0 to 4? x+y+z=0 => x+y = 4.
    // If z=-4, max x is 4 (y=0) to min x=0 (y=4).

    for (int r = 0; r < 9; r++) {
      int z = r - 4; // -4 to 4
      int count = 9 - z.abs();
      // Let's verify:
      // if z=-4, count=5. x ranges?
      // x+y-4=0 => x+y=4.
      // constraints: |x|<=4, |y|<=4.
      // valid x: 0, 1, 2, 3, 4 -> y: 4, 3, 2, 1, 0. All valid.
      // So startX = 0?
      // Wait, standard pointy-topped hexes or flat-topped?
      // main.dart draws horizontal lines, suggesting flat-topped orientation rows?
      // Or pointy-topped with horizontal rows.
      // Usually "rows" imply z=const in cube coords for flat-topped?

      // Let's just use a known generator.
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
    // Sort selection to process from front to back to avoid overwriting
    // Actually, we need to know if it's inline or broadside.
    // MoveValidator logic helps, but here we just need to execute.

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
    // Move each marble to neighbor
    // Since broadside moves to empty space (validated), order doesn't matter much
    // UNLESS we are moving into a space that was occupied by another marble in the selection?
    // No, broadside means moving perpendicular to the line, so paths don't overlap.

    // Map of new states
    Map<HexCoordinate, MarbleState> newStates = {};
    for (var c in selection) {
      newStates[c.neighbor(dir)] = _grid[c]!;
      _grid[c] = MarbleState.empty;
    }
    _grid.addAll(newStates);
  }

  void _executeInlineMove(List<HexCoordinate> selection, Direction dir) {
    // Find the leading marble
    HexCoordinate? tip;
    for (var c in selection) {
      if (!selection.contains(c.neighbor(dir))) {
        tip = c;
        break;
      }
    }

    if (tip == null) return; // Should not happen

    // Check if pushing
    var current = tip.neighbor(dir);
    List<HexCoordinate> toPush = [];

    while (isValid(current) && _grid[current] != MarbleState.empty) {
      toPush.add(current);
      current = current.neighbor(dir);
    }

    // If current is invalid (off board) and we have marbles to push,
    // the last one falls off.
    bool pushOff = !isValid(current);

    if (pushOff) {
      // The last marble in toPush falls off
      if (toPush.isNotEmpty) {
        var fallen = toPush.last;
        var state = _grid[fallen]!;
        if (state == MarbleState.holographic) holoCaptured++;
        if (state == MarbleState.quantum) quantumCaptured++;
        // Remove it from grid effectively (it will be overwritten or cleared)
        // Actually, we shift everything.
      }
    }

    // Execution:
    // Move marbles in toPush
    // If not pushOff, the last one moves to 'current' (empty).
    // If pushOff, the last one is removed.

    if (!pushOff) {
      // Move the stack forward into the empty space
      // Iterate backwards from empty space
      // current is empty.
      // previous was toPush.last

      // Simpler: Just shift values.
      // target <- source
      // current <- toPush.last
      // toPush.last <- toPush[last-1]
      // ...
      // toPush.first <- tip
      // tip <- tip-1 ...

      // Let's use a list of all coordinates involved in the move
      // From tip (exclusive) to current (inclusive).

      // Actually, we are moving the player's marbles AND the opponent's marbles.
      // The player's marbles are `selection`.
      // The opponent's marbles are `toPush`.

      // We move everything one step in `dir`.

      // New positions:
      // For each c in selection: c -> c.neighbor(dir)
      // For each c in toPush: c -> c.neighbor(dir)

      // We must process from front (closest to empty space/edge) to back to avoid overwrite.

      // Sort them by projection on direction?
      // Or just standard logic:
      // If we move to `current` (empty), we can just move the last one there, then next one to last one's pos...

      // Wait, `toPush` contains opponent marbles.
      // `selection` contains player marbles.
      // They are all contiguous in a line.
      // `tip` is the front of `selection`.
      // `toPush` are in front of `tip`.

      // So the line is:
      // [Back of selection] ... [Tip] [toPush 0] ... [toPush N] [Empty/Edge]

      // We move everything towards [Empty/Edge].
      // We should start moving from [toPush N] to [Empty/Edge].
      // Then [toPush N-1] to [toPush N]...
      // ...
      // [Tip] to [toPush 0]
      // ...
      // [Back] to [Back+1]
      // And finally [Back] becomes empty.
    }

    // Construct the full chain of coordinates starting from the empty space/off-board working backwards.
    // The chain ends at the back of the selection.

    // Chain:
    // Dest: current (if valid)
    // Source: current - dir (should be toPush.last or tip)

    // We can just iterate the list of ALL affected cells.
    // Affected: selection + toPush.
    // Destination for each is neighbor(dir).

    // We need to handle the one falling off separately if pushOff.

    // Let's collect all marbles to be moved.
    List<HexCoordinate> moving = [];
    moving.addAll(toPush); // Opponents
    moving.addAll(selection); // Players

    // We need to move them.
    // If pushOff, the first one in `toPush` (the one furthest away from selection? No, `toPush` order depends on loop)
    // In my loop: `toPush` adds `current` starting from `tip.neighbor`.
    // So `toPush[0]` is adjacent to `tip`.
    // `toPush.last` is the one at the edge.

    // If pushOff, `toPush.last` falls off.
    if (pushOff && toPush.isNotEmpty) {
        var fallen = toPush.last;
        var state = _grid[fallen]!;
        // Already captured above.
        // But we need to update grid?
        // Wait, I cleared it in previous code?
        // In this version, I removed the `_grid[fallen] = empty` line?
        // No, I replaced the block.
        // Let's check what I wrote in `write_file` above.
        // I did NOT include `_grid[fallen] = MarbleState.empty;` in the first `if (pushOff)` block.
        // So the grid is not modified yet.

        // But then later:
        // `if (pushOff && toPush.isNotEmpty)`
        // `var fallen = toPush.last;`
        // `state = _grid[fallen]!;`
        // I REMOVED the capture logic from here in previous steps?
        // No, in previous `replace` steps I was fiddling with this.

        // In the `write_file` content I just prepared, I have:
        // `if (pushOff && toPush.isNotEmpty) { ... capture logic ... }`

        // And then below:
        // `if (pushOff && toPush.isNotEmpty) { var fallen ... _grid[fallen] = MarbleState.empty; }`

        // Wait, look at `write_file` content I constructed in thought block.
        // I put the capture logic back in the first block.
        // But I removed the clearing logic?

        // Let's look at lines 343 in `write_file` content.
        /*
        if (pushOff && toPush.isNotEmpty) {
            var fallen = toPush.last;
            var state = _grid[fallen]!;
            if (state == MarbleState.holographic) holoCaptured++;
            if (state == MarbleState.quantum) quantumCaptured++;
            _grid[fallen] = MarbleState.empty; // Cleared
        }
        */

        // Wait, if I have TWO blocks that do capture?
        // Block 1 (lines 260): `if (pushOff) { ... capture ... }`
        // Block 2 (lines 343): `if (pushOff && toPush.isNotEmpty) { ... capture ... }`

        // If I have BOTH, then I capture twice!

        // In the `write_file` above, I have:
        // Line 257: `if (pushOff) { ... capture logic ... }`
        // Line 343: `if (pushOff && toPush.isNotEmpty) { ... another capture logic ... }`

        // YES! That is the bug! I duplicated the logic in my `write_file` (and likely in my previous patches).

        // I need to remove one of them.
        // The second one seems to be part of the `Execution` phase logic structure I built.
        // The first one was "Check if pushing" phase.

        // I will remove the first block's capture logic or merge them.
        // I'll remove the first block entirely or just the capture part?
        // The first block:
        /*
        if (pushOff) {
          if (toPush.isNotEmpty) {
             // ... capture ...
          }
        } else {
           // Empty space ...
        }
        */
        // This `if/else` was distinguishing between push-off and push-to-empty.

        // I should probably do capture logic ONCE.
    }

    // ...

    // Let's sort moving list by distance from tip in direction `dir`.
    // `toPush` is already sorted from tip outwards.
    // `selection` needs sorting.
    // Tip is closest to push. Tail is furthest.
    // We want to process from Front (Push end) to Back (Tail).

    // `toPush` is [closest to tip, ..., furthest].
    // `selection` is mixed.

    // Full line from Front (dest) to Back (source):
    // [toPush.last, ..., toPush.first, tip, ..., tail]

    // Dest for toPush.last is neighbor(dir).
    // ...

    // If pushOff:
    //   toPush.last moves to void (capture).
    //   toPush[last-1] moves to toPush.last.
    //   ...
    //   toPush[0] moves to toPush[1].
    //   tip moves to toPush[0].
    //   ...
    //   tail moves to ...
    //   tail position becomes empty.

    // If not pushOff:
    //   toPush.last moves to neighbor(dir) (which is empty).
    //   ... same chain.

    // Implementation:
    // 1. Capture if needed.
    if (pushOff && toPush.isNotEmpty) {
       // captured already handled above
    }

    // 2. Shift values.
    // We need an ordered list of coordinates on the board that are affected.
    // Excluding the one that fell off? No, we need its coordinate to put the previous one there.

    // Ordered list from Front (furthest in dir) to Back.
    List<HexCoordinate> line = [];
    if (toPush.isNotEmpty) {
      line.addAll(toPush.reversed); // Furthest first
    }

    // Sort selection.
    // Project on dir vector?
    // Or just start from tip and go backwards.
    List<HexCoordinate> selectionSorted = [];
    var curr = tip;
    while (selection.contains(curr)) {
      selectionSorted.add(curr!);
      curr = curr.neighbor(_opposite(dir)); // Go backwards
    }
    // selectionSorted is now [tip, ..., tail].

    line.addAll(selectionSorted);

    // Now line is [toPush.last, ..., toPush.first, tip, ..., tail]

    // Move loop
    for (var c in line) {
      var dest = c.neighbor(dir);
      if (isValid(dest)) {
        _grid[dest] = _grid[c]!;
      }
    }

    // 3. Clear tail
    // The last element in `line` is the tail.
    var tailCoord = line.last;
    _grid[tailCoord] = MarbleState.empty;
  }

  Direction _opposite(Direction d) {
    int idx = (d.index + 3) % 6;
    return Direction.values[idx];
  }
}

class MoveValidator {
  final Board board;

  MoveValidator(this.board);

  // Checks if a selection (list of coordinates) is valid for the current player
  // 1. All coords must contain player's marbles.
  // 2. All coords must be inline (collinear).
  // 3. Count must be 1, 2, or 3.
  // 4. Coords must be adjacent.
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
    // Sort logic needed or check if they form a line.
    // For 2 or 3, calculate direction.

    // Sort by x, then y, then z to ensure order?
    // Or just check if direction is consistent.

    var first = selection[0];
    var second = selection[1];
    var dir = first.directionTo(second);
    if (dir == null) return false; // Not adjacent

    if (selection.length == 3) {
      // Check if 3rd is adjacent to 2nd in same direction
      // OR if 3rd is adjacent to 1st in opposite direction (if array not sorted)
      // Simpler: sort them along the axis of direction.

      // But we can just check if they are collinear.
      // x, y, z arithmetic progression.
      // e.g. x coords: 0, 1, 2.

      // Let's sort simply?
      // Actually, main UI might pass them in any order.
      // Let's assume we need to validate "connected line".
      // We can try to construct a line from min to max.
    }

    return _areInline(selection);
  }

  bool _areInline(List<HexCoordinate> selection) {
    if (selection.length <= 1) return true;

    // Find direction from 0 to 1
    // We need to handle unsorted input.
    // Let's try all pairs? No.
    // Pick one, find neighbor in selection, chain them.

    // Better:
    // If size 2: must be neighbors.
    // If size 3: must be A-B-C line.

    if (selection.length == 2) {
      return selection[0].directionTo(selection[1]) != null;
    }

    if (selection.length == 3) {
      // 3 permutations?
      // A-B-C, A-C-B, B-A-C...
      // Just check if there exists a middle element adjacent to other two.
      for (var mid in selection) {
        var others = selection.where((c) => c != mid).toList();
        if (others.length != 2) continue; // duplicate coords?
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
    // index diff is 3?
    return (d1.index - d2.index).abs() == 3;
  }

  // Validates a move
  // Selection: valid selection coordinates
  // Direction: move direction
  bool validateMove(List<HexCoordinate> selection, Direction dir, PlayerSide player) {
    if (!validateSelection(selection, player)) return false;

    // Classify move: Inline or Broadside
    if (_isInlineMove(selection, dir)) {
      return _validateInlineMove(selection, dir, player);
    } else {
      return _validateBroadsideMove(selection, dir);
    }
  }

  bool _isInlineMove(List<HexCoordinate> selection, Direction dir) {
    if (selection.length == 1) return true;
    // If direction matches the line of selection
    var lineDir = selection[0].directionTo(selection[1]);
    if (lineDir == null) return false; // Should satisfy validateSelection

    return lineDir == dir || _isOpposite(lineDir, dir);
  }

  bool _validateBroadsideMove(List<HexCoordinate> selection, Direction dir) {
    // For broadside, all destination cells must be empty.
    for (var c in selection) {
      var dest = c.neighbor(dir);
      if (!board.isValid(dest)) return false; // Off board?
      if (board.get(dest) != MarbleState.empty) return false;
    }
    return true;
  }

  bool _validateInlineMove(List<HexCoordinate> selection, Direction dir, PlayerSide player) {
    // Find the "leading" marble (the one moving into non-self space)
    // There can be only one leading marble in inline move.

    // Sort selection in direction of move.
    // e.g. moving East. Sort by HexCoordinate projected on East vector?
    // Or just find the one whose neighbor(dir) is NOT in selection.

    HexCoordinate? tip;
    for (var c in selection) {
      if (!selection.contains(c.neighbor(dir))) {
        tip = c;
        break;
      }
    }

    if (tip == null) return false; // Should not happen for valid line

    // Check what's in front of tip
    var current = tip.neighbor(dir);
    int pushStrength = selection.length;
    int opponentCount = 0;

    MarbleState opponentMarble = player == PlayerSide.holographic
        ? MarbleState.quantum
        : MarbleState.holographic;

    while (true) {
      if (!board.isValid(current)) {
        // Pushing off board?
        // Only if we are pushing opponent.
        if (opponentCount > 0) {
           // Valid push off board!
           return pushStrength > opponentCount;
        }
        // Cannot move own marble off board voluntarily
        return false;
      }

      var state = board.get(current);
      if (state == MarbleState.empty) {
        // Found empty space, move is valid if strength > opponentCount
        return pushStrength > opponentCount;
      } else if (state == opponentMarble) {
        opponentCount++;
        if (opponentCount >= pushStrength) {
          return false; // Cannot push equal or greater number
        }
        // Continue checking next cell
      } else {
        // Blocked by own marble (should have been in selection if we wanted to move it)
        return false;
      }

      current = current.neighbor(dir);
    }
  }
}
