import 'package:flutter/material.dart';
import 'package:icosatabolne/visuals/game_config.dart';
import 'dart:math';

class FallbackPainter extends CustomPainter {
  final GameVib3Config config;
  final double animationValue;
  final double chaos;
  final double speed;
  final double hue;

  FallbackPainter({
    required this.config,
    this.animationValue = 0,
    this.chaos = 0.0,
    this.speed = 1.0,
    this.hue = 200,
  });

  Color _shiftHue(Color color, double shift) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + shift) % 360).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Apply jitter based on chaos
    final rng = Random();
    Offset jitter = Offset.zero;
    if (chaos > 0) {
      jitter = Offset(
        (rng.nextDouble() - 0.5) * chaos * 10,
        (rng.nextDouble() - 0.5) * chaos * 10,
      );
    }

    if (config.system == 'holographic') {
      _paintHolographic(canvas, center + jitter, radius);
    } else {
      _paintQuantum(canvas, center + jitter, radius);
    }
  }

  void _paintHolographic(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Adjust color based on hue parameter
    // Hue param is absolute, usually 0-360.
    // Default cyan is around 180. Magenta around 300.
    // If hue is provided, we might want to override or shift.
    // Let's assume 'hue' is a shift from base. Or absolute.
    // Let's treat it as a shift for simplicity with existing colors.
    double hueShift = hue - 200; // 200 is default passed

    paint.color = _shiftHue(Colors.cyanAccent, hueShift).withOpacity(0.8);
    canvas.drawCircle(center, radius * 0.8, paint);

    paint.color = _shiftHue(Colors.purpleAccent, hueShift).withOpacity(0.8);
    // Chaos affects glitch offset too
    double glitch = 2 + chaos * 5;
    canvas.drawCircle(center + Offset(glitch, glitch), radius * 0.8, paint);

    // Grid lines (Hex)
    paint.color = Colors.white.withOpacity(0.3);
    double effectiveSpeed = speed;

    for (int i = 0; i < 6; i++) {
        double angle = i * pi / 3 + animationValue * effectiveSpeed;
        canvas.drawLine(
            center,
            center + Offset(cos(angle), sin(angle)) * radius * 0.8,
            paint
        );
    }
  }

  void _paintQuantum(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;
    double hueShift = hue - 200;

    // Gradient
    final gradient = RadialGradient(
      colors: [
        _shiftHue(Colors.purpleAccent, hueShift),
        _shiftHue(Colors.deepPurple, hueShift),
        Colors.black
      ],
      stops: [0.2, 0.7, 1.0],
    );

    paint.shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.9, paint);

    // Gold particles (simulated)
    paint.shader = null;
    paint.color = Colors.amberAccent;

    // Chaos adds more particles?
    int particleCount = 10 + (chaos * 20).toInt();

    final rng = Random(config.geometry);
    for (int i = 0; i < particleCount; i++) {
        double r = rng.nextDouble() * radius * 0.8;
        // Speed affects rotation
        double theta = rng.nextDouble() * 2 * pi + animationValue * 2 * speed;

        if (chaos > 0.5) {
             theta += (Random().nextDouble() - 0.5); // Random jitter
        }

        canvas.drawCircle(
            center + Offset(r * cos(theta), r * sin(theta)),
            2,
            paint
        );
    }
  }

  @override
  bool shouldRepaint(covariant FallbackPainter oldDelegate) {
    return oldDelegate.config != config ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.chaos != chaos ||
           oldDelegate.speed != speed ||
           oldDelegate.hue != hue;
  }
}
