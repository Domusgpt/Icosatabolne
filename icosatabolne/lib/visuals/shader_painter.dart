import 'dart:ui';
import 'package:flutter/material.dart';

class ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final double chaos;
  final double geometry; // 0.0 or 1.0 (or mapped from int)
  final double hue;
  final double saturation;
  final double intensity;

  ShaderPainter({
    required this.shader,
    required this.time,
    required this.chaos,
    required this.geometry,
    required this.hue,
    required this.saturation,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set Uniforms
    // 0: uSize.x
    // 1: uSize.y
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2: uTime
    shader.setFloat(2, time);

    // 3: uChaos
    shader.setFloat(3, chaos);

    // 4: uGeometry
    shader.setFloat(4, geometry);

    // 5: uHue
    shader.setFloat(5, hue);

    // 6: uSaturation
    shader.setFloat(6, saturation);

    // 7: uIntensity
    shader.setFloat(7, intensity);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.chaos != chaos ||
           oldDelegate.geometry != geometry ||
           oldDelegate.hue != hue ||
           oldDelegate.saturation != saturation ||
           oldDelegate.intensity != intensity;
  }
}
