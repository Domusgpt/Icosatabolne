import 'package:flutter/material.dart';
import 'dart:math';

class VisualEffectsLayer extends StatelessWidget {
  final Widget child;
  final double chaos;
  final double intensity;

  const VisualEffectsLayer({
    super.key,
    required this.child,
    required this.chaos,
    this.intensity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // If not chaotic enough, just return child to save performance/structure
    if (chaos <= 0.05) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Content with Glitch
        _GlitchEffect(
          chaos: chaos,
          child: child,
        ),

        // Chromatic Aberration
        if (chaos > 0.1)
          _ChromaticAberration(
            offset: Offset(chaos * 5, 0),
            color: Colors.red.withOpacity(0.3 * chaos),
            child: child,
          ),
        if (chaos > 0.1)
          _ChromaticAberration(
            offset: Offset(-chaos * 5, 0),
            color: Colors.blue.withOpacity(0.3 * chaos),
            child: child,
          ),

        // Scanlines
        _ScanlineEffect(chaos: chaos),

        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.5 - (chaos * 0.5),
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2 + chaos * 0.4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChromaticAberration extends StatelessWidget {
  final Widget child;
  final Offset offset;
  final Color color;

  const _ChromaticAberration({
    required this.child,
    required this.offset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            colors: [color, color],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcATop,
        child: child,
      ),
    );
  }
}

class _GlitchEffect extends StatefulWidget {
  final Widget child;
  final double chaos;

  const _GlitchEffect({required this.child, required this.chaos});

  @override
  State<_GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<_GlitchEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chaos < 0.2) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (Random().nextDouble() > widget.chaos) return widget.child;

        // Random slice offset
        double y = Random().nextDouble() * 200 - 100;
        double x = (Random().nextDouble() - 0.5) * widget.chaos * 20;

        return Transform.translate(
          offset: Offset(x, 0),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _ScanlineEffect extends StatelessWidget {
  final double chaos;

  const _ScanlineEffect({required this.chaos});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinePainter(chaos),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double chaos;

  _ScanlinePainter(this.chaos);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05 + chaos * 0.1)
      ..strokeWidth = 1.0;

    double step = 4.0;
    if (chaos > 0.5) step = 2.0;

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => oldDelegate.chaos != chaos;
}
