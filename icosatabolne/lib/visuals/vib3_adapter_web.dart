import 'package:flutter/material.dart';
import 'package:icosatabolne/visuals/game_config.dart';
import 'package:icosatabolne/visuals/fallback_painter.dart';

class Vib3Adapter extends StatefulWidget {
  final GameVib3Config config;
  final double width;
  final double height;
  final bool animate;
  final double chaos;
  final double speed;
  final double hue;
  final double saturation;
  final double intensity;

  // Advanced Params (Optional - if null, auto-derived)
  final double? rotXY;
  final double? rotXZ;
  final double? rotYZ;
  final double? rotXW;
  final double? rotYW;
  final double? rotZW;
  final double? distortion;
  final double? zoom;
  final double? geometryMorph;

  const Vib3Adapter({
    super.key,
    required this.config,
    this.width = 100,
    this.height = 100,
    this.animate = true,
    this.chaos = 0.0,
    this.speed = 1.0,
    this.hue = 200,
    this.saturation = 0.8,
    this.intensity = 0.9,
    this.rotXY,
    this.rotXZ,
    this.rotYZ,
    this.rotXW,
    this.rotYW,
    this.rotZW,
    this.distortion,
    this.zoom,
    this.geometryMorph,
  });

  @override
  State<Vib3Adapter> createState() => _Vib3AdapterState();
}

class _Vib3AdapterState extends State<Vib3Adapter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: FallbackPainter(
            config: widget.config,
            animationValue: _controller.value * 2 * 3.14159, // 2*PI
            chaos: widget.chaos,
            speed: widget.speed,
            hue: widget.hue,
          ),
        );
      },
    );
  }
}
