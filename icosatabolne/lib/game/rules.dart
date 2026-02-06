import 'board_state.dart';
import 'hex_grid.dart';

enum MoveType {
  inline,
  broadside,
}

class MoveResult {
  final bool isValid;
  final String? error;
  final MoveType? type;
  final List<Hex> movingMarbles; // Your marbles being moved
  final List<Hex> pushedMarbles; // Opponent marbles being pushed
  final Hex? eliminatedMarble; // Marble pushed off board

  MoveResult({
    required this.isValid,
    this.error,
    this.type,
    this.movingMarbles = const [],
    this.pushedMarbles = const [],
    this.eliminatedMarble,
  });

  factory MoveResult.invalid(String error) => MoveResult(isValid: false, error: error);

  factory MoveResult.success({
    required MoveType type,
    required List<Hex> movingMarbles,
    List<Hex> pushedMarbles = const [],
    Hex? eliminatedMarble,
  }) => MoveResult(
    isValid: true,
    type: type,
    movingMarbles: movingMarbles,
    pushedMarbles: pushedMarbles,
    eliminatedMarble: eliminatedMarble,
  );
}

class Rules {
  static MoveResult validateMove(BoardState board, List<Hex> selection, HexDirection direction) {
    if (selection.isEmpty) return MoveResult.invalid("No marbles selected");
    if (selection.length > 3) return MoveResult.invalid("Too many marbles selected");

    // Check if all selected marbles belong to same player
    Player? firstPlayer = board.getPiece(selection.first);
    if (firstPlayer == null) return MoveResult.invalid("Empty hex selected");

    for (var hex in selection) {
      if (board.getPiece(hex) != firstPlayer) {
        return MoveResult.invalid("Selection must be single player's marbles");
      }
    }

    // Check if selection is a line (adjacent)
    if (!_areAligned(selection)) {
      return MoveResult.invalid("Selection must be in a line");
    }

    // Determine move type
    // If direction is parallel to the line of selection -> In-line
    // Else -> Broadside

    // Direction of the selection line
    HexDirection? lineDir;
    if (selection.length > 1) {
      lineDir = Hex.getDirection(selection[0], selection[1]);
      // Verify all are on this line
      // Actually _areAligned checked connectivity, but strict line check:
      // Sort selection to ensure adjacency check is simple?
      // Better: check if direction matches the line axis.
    }

    bool isInline = false;
    if (selection.length == 1) {
      isInline = true; // Single marble is always inline (conceptually simple move)
    } else {
      // Check if move direction is same or opposite to line direction
      // HexDirection doesn't support easy parallel check without logic
      // But we can check if moving each marble lands on another selected marble?
      // In broadside, all target hexes are empty (or at least not part of selection).
      // In inline, the "head" moves into empty/opponent, "tail" leaves space for "middle".

      // Let's check relation between lineDir and direction
      if (lineDir == direction || lineDir == direction.opposite) {
        isInline = true;
      }
    }

    if (isInline) {
      return _validateInline(board, selection, direction, firstPlayer);
    } else {
      return _validateBroadside(board, selection, direction, firstPlayer);
    }
  }

  static bool _areAligned(List<Hex> selection) {
    if (selection.length <= 1) return true;

    // Sort to handle arbitrary order
    // But sorting Hex is 2D.
    // Let's just pick one, find neighbor, continue.
    // Or check if all lie on a line.
    // Line eq: q=const OR r=const OR s=const.

    bool sameQ = selection.every((h) => h.q == selection[0].q);
    bool sameR = selection.every((h) => h.r == selection[0].r);
    bool sameS = selection.every((h) => h.s == selection[0].s);

    if (!sameQ && !sameR && !sameS) return false;

    // Must also be adjacent (no gaps)
    // Find min and max on the changing coordinate
    // Check if length matches range
    // ... implementation detail.
    // Simple check: for 2 or 3 items, just check distance.
    if (selection.length == 2) {
      return selection[0].distanceTo(selection[1]) == 1;
    }
    if (selection.length == 3) {
      // Should be 1-1-1 distance or similar.
      // Sort by the changing coordinate.
      // If sameQ, vary R.
      var sorted = List<Hex>.from(selection);
      if (sameQ) sorted.sort((a, b) => a.r.compareTo(b.r));
      else if (sameR) sorted.sort((a, b) => a.q.compareTo(b.q));
      else sorted.sort((a, b) => a.q.compareTo(b.q)); // s varies, so q varies too

      return sorted[0].distanceTo(sorted[1]) == 1 && sorted[1].distanceTo(sorted[2]) == 1;
    }
    return true;
  }

  static MoveResult _validateBroadside(BoardState board, List<Hex> selection, HexDirection direction, Player player) {
    // Broadside: All target hexes must be empty.
    for (var hex in selection) {
      Hex target = hex.neighbor(direction);
      if (!board.isValidHex(target)) return MoveResult.invalid("Move off board");
      if (board.getPiece(target) != null) return MoveResult.invalid("Broadside blocked");
    }
    return MoveResult.success(type: MoveType.broadside, movingMarbles: selection);
  }

  static MoveResult _validateInline(BoardState board, List<Hex> selection, HexDirection direction, Player player) {
    // Sort selection in direction of movement.
    // The "head" is the one furthest in the direction.
    // We project position onto direction vector?
    // Simply: which marble has a neighbor in 'direction' that is NOT in selection?
    // In a line of 3, only one marble (the head) is adjacent to a non-selected hex in that direction.

    Hex? head;
    for (var h in selection) {
      if (!selection.contains(h.neighbor(direction))) {
        head = h;
        break;
      }
    }

    if (head == null) return MoveResult.invalid("Internal error: Could not find head of line");

    // Now check what is in front of head
    Hex current = head;
    List<Hex> pushed = [];

    // We can push up to (Selection Length - 1) opponent marbles?
    // No. 3 pushes 2, 3 pushes 1, 2 pushes 1.
    // Rule: My strength > Opponent strength.

    int myStrength = selection.length;
    int opponentStrength = 0;

    while (true) {
      current = current.neighbor(direction);

      // If off board
      if (!board.isValidHex(current)) {
        // If we are pushing opponent, they are eliminated.
        // If we are just moving into void, it's suicide (allowed in some variants, but standard usually says no suicide unless pushing?)
        // Actually standard Abalone: You cannot move your own marble off board.
        // You can only push OPPONENT off board.
        if (opponentStrength > 0) {
           return MoveResult.success(
             type: MoveType.inline,
             movingMarbles: selection,
             pushedMarbles: pushed,
             eliminatedMarble: pushed.last // The last one in the chain falls off
           );
        } else {
          return MoveResult.invalid("Cannot move self off board");
        }
      }

      Player? p = board.getPiece(current);
      if (p == null) {
        // Empty spot. Move is valid.
        return MoveResult.success(
          type: MoveType.inline,
          movingMarbles: selection,
          pushedMarbles: pushed
        );
      } else if (p == player) {
        // Blocked by own piece
        return MoveResult.invalid("Blocked by own piece");
      } else {
        // Opponent piece
        opponentStrength++;
        pushed.add(current);

        if (opponentStrength >= myStrength) {
          return MoveResult.invalid("Cannot push: Insufficient strength");
        }
      }
    }
  }
}
