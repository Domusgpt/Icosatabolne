import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:icosatabolne/logic/sound_haptics_manager.dart';
import 'package:icosatabolne/game/game_events.dart';
import 'board_state.dart';
import 'hex_grid.dart';
import 'rules.dart';

class GameController extends ChangeNotifier {
  final SoundHapticsManager _haptics = SoundHapticsManager();
  BoardState _board;
  Player _currentTurn;
  int _turnCount;
  final Map<Player, int> _capturedMarbles;
  String? _lastError;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  GameController()
      : _board = BoardState.initial(),
        _currentTurn = Player.holographic, // Black starts
        _turnCount = 1,
        _capturedMarbles = {
          Player.holographic: 0,
          Player.quantum: 0,
        };

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

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }

  void reset() {
    _board = BoardState.initial();
    _currentTurn = Player.holographic;
    _turnCount = 1;
    _capturedMarbles[Player.holographic] = 0;
    _capturedMarbles[Player.quantum] = 0;
    _lastError = null;
    _eventController.add(const GameResetEvent());
    notifyListeners();
  }

  bool makeMove(List<Hex> selection, HexDirection direction) {
    if (isGameOver) {
      _lastError = "Game Over";
      _haptics.playErrorEffect();
      notifyListeners();
      return false;
    }

    MoveResult result = Rules.validateMove(_board, selection, direction);

    if (!result.isValid) {
      _lastError = result.error;
      _haptics.playErrorEffect();
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

    for (var hex in result.pushedMarbles) {
      // If this marble is eliminated, do not add it back.
      if (hex == result.eliminatedMarble) {
        // Captured!
        // Who captured it? The mover.
        _capturedMarbles[mover] = (_capturedMarbles[mover] ?? 0) + 1;
      } else {
        newPieces[hex.neighbor(direction)] = opponent;
      }
    }

    // Play appropriate haptic effect & Emit Event
    if (result.eliminatedMarble != null) {
      _haptics.playCaptureEffect();
      _eventController.add(CaptureEvent(
        player: mover,
        capturedMarble: result.eliminatedMarble!,
        totalCapturedByPlayer: _capturedMarbles[mover] ?? 0
      ));
    } else if (result.pushedMarbles.isNotEmpty) {
      _haptics.playPushEffect();
      _eventController.add(PushEvent(
        player: mover,
        movingMarbles: result.movingMarbles,
        pushedMarbles: result.pushedMarbles,
        direction: direction,
      ));
    } else {
      _haptics.playMoveEffect();
      _eventController.add(MoveEvent(
        player: mover,
        movingMarbles: result.movingMarbles,
        direction: direction,
      ));
    }

    _board = BoardState(pieces: newPieces, radius: _board.radius);
    _currentTurn = (mover == Player.holographic) ? Player.quantum : Player.holographic;
    _turnCount++;
    _lastError = null;

    if (isGameOver) {
      Player? w = winner;
      if (w != null) {
        _haptics.playWinEffect();
        _eventController.add(GameOverEvent(winner: w, finalScore: _capturedMarbles[w]!));
      }
    }

    notifyListeners();
    return true;
  }
}
