import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/game/hex_grid.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/ui/marble_widget.dart';
import 'package:icosatabolne/visuals/vib3_shim.dart';
import 'package:provider/provider.dart';

class BoardWidget extends StatefulWidget {
  final double size;
  final bool animateMarbles;
  final Vib3Engine? quantumEngine;
  final Vib3Engine? holographicEngine;

  const BoardWidget({
    super.key,
    required this.size,
    this.animateMarbles = true,
    this.quantumEngine,
    this.holographicEngine,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  List<Hex> _selection = [];
  late double _hexSize;
  late Offset _center;

  Offset? _dragStartPos;
  Offset _dragDelta = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    _hexSize = widget.size / 14.0;
    _center = Offset(widget.size / 2, widget.size / 2);

    final controller = context.watch<GameController>();
    final board = controller.board;

    return GestureDetector(
      onTapUp: (details) => _handleTap(details, controller),
      onPanStart: (details) => _handlePanStart(details),
      onPanUpdate: (details) => _handlePanUpdate(details),
      onPanEnd: (details) => _handlePanEnd(details, controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: Colors.transparent, // Hit test
        child: Stack(
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: BoardPainter(hexSize: _hexSize, radius: 4),
            ),
            ...board.pieces.entries.map((entry) {
              final hex = entry.key;
              final player = entry.value;
              final pos = _hexToPixel(hex);

              int lost = controller.capturedMarbles[player] ?? 0;
              double chaos = lost / 6.0;

              // Select shared engine based on player type
              final engine = player == Player.quantum
                  ? widget.quantumEngine
                  : widget.holographicEngine;

              return Positioned(
                left: pos.dx - _hexSize * 0.8,
                top: pos.dy - _hexSize * 0.8,
                child: MarbleWidget(
                  player: player,
                  size: _hexSize * 1.6,
                  isSelected: _selection.contains(hex),
                  chaosLevel: chaos,
                  animate: widget.animateMarbles,
                  engine: engine, // Pass shared engine
                ),
              );
            }).toList(),

            if (_isDragging && _selection.isNotEmpty && _dragDelta.distance > 10)
              Positioned(
                 left: _hexToPixel(_selection.first).dx,
                 top: _hexToPixel(_selection.first).dy,
                 child: Transform.rotate(
                    angle: _dragDelta.direction,
                    child: Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.5), size: 40),
                 )
              )
          ],
        ),
      ),
    );
  }

  Offset _hexToPixel(Hex hex) {
    var x = _hexSize * (3.0 / 2.0 * hex.q);
    var y = _hexSize * sqrt(3) * (hex.r + hex.q / 2.0);
    return Offset(x, y) + _center;
  }

  Hex _pixelToHex(Offset px) {
    Offset pt = px - _center;
    var q = (2.0 / 3.0 * pt.dx) / _hexSize;
    var r = (-1.0 / 3.0 * pt.dx + sqrt(3) / 3.0 * pt.dy) / _hexSize;
    return _axialRound(q, r);
  }

  Hex _axialRound(double q, double r) {
    var s = -q - r;
    int qi = q.round();
    int ri = r.round();
    int si = s.round();
    var q_diff = (qi - q).abs();
    var r_diff = (ri - r).abs();
    var s_diff = (si - s).abs();
    if (q_diff > r_diff && q_diff > s_diff) {
      qi = -ri - si;
    } else if (r_diff > s_diff) {
      ri = -qi - si;
    }
    return Hex(qi, ri);
  }

  void _handleTap(TapUpDetails details, GameController controller) {
    Hex hex = _pixelToHex(details.localPosition);
    Player? piece = controller.board.getPiece(hex);

    if (piece == controller.currentTurn) {
      setState(() {
        if (_selection.contains(hex)) {
          _selection.remove(hex);
        } else {
          if (_selection.isEmpty) {
            _selection.add(hex);
          } else {
             if (_selection.length < 3) {
                _selection.add(hex);
             } else {
                _selection = [hex];
             }
          }
        }
      });
      HapticFeedback.selectionClick();
    } else {
      if (_selection.isNotEmpty) {
        setState(() => _selection.clear());
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    Hex hex = _pixelToHex(details.localPosition);
    if (_selection.contains(hex)) {
      _isDragging = true;
      _dragStartPos = details.localPosition;
      _dragDelta = Offset.zero;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _dragDelta += details.delta;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details, GameController controller) {
    if (_isDragging) {
      _isDragging = false;
      if (_dragDelta.distance > 30) {
        double angle = _dragDelta.direction;
        int index = ((angle / (pi / 3)).round()) % 6;
        if (index < 0) index += 6;
        HexDirection dir = HexDirection.values[index];
        bool success = controller.makeMove(_selection, dir);
        if (success) {
           HapticFeedback.heavyImpact();
           setState(() => _selection.clear());
        } else {
           HapticFeedback.vibrate();
        }
      }
    }
    _dragDelta = Offset.zero;
  }
}

class BoardPainter extends CustomPainter {
  final double hexSize;
  final int radius;

  BoardPainter({required this.hexSize, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
       ..color = Colors.cyanAccent.withOpacity(0.1)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1;

    for (int q = -radius; q <= radius; q++) {
        int r1 = max(-radius, -q - radius);
        int r2 = min(radius, -q + radius);
        for (int r = r1; r <= r2; r++) {
            Offset pos = _hexToPixel(Hex(q, r), center, hexSize);
            canvas.drawCircle(pos, hexSize * 0.85, paint);
            canvas.drawCircle(pos, hexSize * 0.85, borderPaint);
        }
    }
  }

  Offset _hexToPixel(Hex hex, Offset center, double size) {
    var x = size * (3.0 / 2.0 * hex.q);
    var y = size * sqrt(3) * (hex.r + hex.q / 2.0);
    return Offset(x, y) + center;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
