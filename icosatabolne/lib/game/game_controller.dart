import 'package:flutter/foundation.dart';
import 'board_state.dart';
import 'hex_grid.dart';
import 'rules.dart';
import 'sound_haptics_manager.dart';

class GameController extends ChangeNotifier {
  BoardState _board;
  Player _currentTurn;
  int _turnCount;
  final Map<Player, int> _capturedMarbles;
  String? _lastError;
  final SoundHapticsManager _soundHaptics = SoundHapticsManager();

  // Dynamic Visual/Haptic Parameters
  double get chaosLevel {
    // 0.0 to 1.0 based on game progression
    // Max turns ~60?
    double progress = (_turnCount / 60).clamp(0.0, 1.0);
    // Also affected by captures
    int totalCaptures = (_capturedMarbles[Player.holographic] ?? 0) +
                        (_capturedMarbles[Player.quantum] ?? 0);
    double tension = (totalCaptures / 12).clamp(0.0, 1.0);
    return (progress * 0.4 + tension * 0.6).clamp(0.0, 1.0);
  }

  double get speedLevel => 1.0 + chaosLevel * 2.0;

  GameController()
      : _board = BoardState.initial(),
        _currentTurn = Player.holographic, // Black starts
        _turnCount = 1,
        _capturedMarbles = {
          Player.holographic: 0,
          Player.quantum: 0,
        };

  @override
  void dispose() {
    _soundHaptics.dispose();
    super.dispose();
  }

  BoardState get board => _board;
  Player get currentTurn => _currentTurn;
  int get turnCount => _turnCount;
  Map<Player, int> get capturedMarbles => Map.unmodifiable(_capturedMarbles);
  String? get lastError => _lastError;

  bool get isGameOver =>
      _capturedMarbles[Player.holographic]! >= 6 ||
      _capturedMarbles[Player.quantum]! >= 6;

  Player? get winner {
    if (_capturedMarbles[Player.holographic]! >= 6) return Player.holographic;
    if (_capturedMarbles[Player.quantum]! >= 6) return Player.quantum;
    return null;
  }

  void reset() {
    _board = BoardState.initial();
    _currentTurn = Player.holographic;
    _turnCount = 1;
    _capturedMarbles[Player.holographic] = 0;
    _capturedMarbles[Player.quantum] = 0;
    _lastError = null;
    notifyListeners();
  }

  bool makeMove(List<Hex> selection, HexDirection direction) {
    if (isGameOver) {
      _lastError = "Game Over";
      notifyListeners();
      return false;
    }

    MoveResult result = Rules.validateMove(_board, selection, direction);

    if (!result.isValid) {
      _lastError = result.error;
      notifyListeners();
      return false;
    }

    // Execute Move
    // 1. Remove moving marbles from old positions
    // 2. Remove pushed marbles from old positions
    // 3. Place them in new positions
    // Be careful with overwriting.
    // Best: Create new state map.

    Map<Hex, Player> newPieces = Map.from(_board.pieces);

    // Remove all involved pieces first to avoid collisions logic
    for (var hex in result.movingMarbles) newPieces.remove(hex);
    for (var hex in result.pushedMarbles) newPieces.remove(hex);

    // Add moving marbles to new positions
    Player mover = _currentTurn;
    for (var hex in result.movingMarbles) {
      newPieces[hex.neighbor(direction)] = mover;
    }

    // Add pushed marbles to new positions
    // Opponent is opposite of mover
    Player opponent = (mover == Player.holographic) ? Player.quantum : Player.holographic;
    bool captureHappened = false;

    for (var hex in result.pushedMarbles) {
      // If this marble is eliminated, do not add it back.
      if (hex == result.eliminatedMarble) {
        // Captured!
        // Who captured it? The mover.
        _capturedMarbles[mover] = (_capturedMarbles[mover] ?? 0) + 1;
        captureHappened = true;
      } else {
        newPieces[hex.neighbor(direction)] = opponent;
      }
    }

    _board = BoardState(pieces: newPieces, radius: _board.radius);
    _currentTurn = (mover == Player.holographic) ? Player.quantum : Player.holographic;
    _turnCount++;
    _lastError = null;

    // Trigger Effects
    if (isGameOver) {
      _soundHaptics.triggerWin();
    } else if (captureHappened) {
      _soundHaptics.triggerCapture(chaosLevel);
    } else {
      _soundHaptics.triggerMove(chaosLevel);
    }

    notifyListeners();
    return true;
  }
}
