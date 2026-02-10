import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/game/hex_grid.dart';

abstract class GameEvent {
  const GameEvent();
}

class MoveEvent extends GameEvent {
  final Player player;
  final List<Hex> movingMarbles;
  final HexDirection direction;

  const MoveEvent({
    required this.player,
    required this.movingMarbles,
    required this.direction,
  });
}

class PushEvent extends GameEvent {
  final Player player;
  final List<Hex> movingMarbles;
  final List<Hex> pushedMarbles;
  final HexDirection direction;

  const PushEvent({
    required this.player,
    required this.movingMarbles,
    required this.pushedMarbles,
    required this.direction,
  });
}

class CaptureEvent extends GameEvent {
  final Player player; // The capturing player
  final Hex capturedMarble;
  final int totalCapturedByPlayer;

  const CaptureEvent({
    required this.player,
    required this.capturedMarble,
    required this.totalCapturedByPlayer,
  });
}

class GameOverEvent extends GameEvent {
  final Player winner;
  final int finalScore;

  const GameOverEvent({
    required this.winner,
    required this.finalScore,
  });
}

class GameResetEvent extends GameEvent {
  const GameResetEvent();
}
