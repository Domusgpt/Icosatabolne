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

  // New 6D Rotation & Effects
  final double rotXY;
  final double rotXZ;
  final double rotYZ;
  final double rotXW;
  final double rotYW;
  final double rotZW;
  final double distortion;
  final double zoom;

  ShaderPainter({
    required this.shader,
    required this.time,
    required this.chaos,
    required this.geometry,
    required this.hue,
    required this.saturation,
    required this.intensity,
    this.rotXY = 0.0,
    this.rotXZ = 0.0,
    this.rotYZ = 0.0,
    this.rotXW = 0.0,
    this.rotYW = 0.0,
    this.rotZW = 0.0,
    this.distortion = 0.0,
    this.zoom = 0.0,
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

    // 8-13: Rotations
    shader.setFloat(8, rotXY);
    shader.setFloat(9, rotXZ);
    shader.setFloat(10, rotYZ);
    shader.setFloat(11, rotXW);
    shader.setFloat(12, rotYW);
    shader.setFloat(13, rotZW);

    // 14: uDistortion
    shader.setFloat(14, distortion);

    // 15: uZoom
    shader.setFloat(15, zoom);

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
           oldDelegate.intensity != intensity ||
           oldDelegate.rotXY != rotXY ||
           oldDelegate.rotXZ != rotXZ ||
           oldDelegate.rotYZ != rotYZ ||
           oldDelegate.rotXW != rotXW ||
           oldDelegate.rotYW != rotYW ||
           oldDelegate.rotZW != rotZW ||
           oldDelegate.distortion != distortion ||
           oldDelegate.zoom != zoom;
  }
}
