import 'package:flutter/material.dart';

class VisualizerController extends ChangeNotifier {
  // Core Visual Parameters (0-1 unless noted)
  double chaos = 0.0;
  double speed = 1.0;
  double hue = 200.0; // 0-360
  double saturation = 0.8;
  double intensity = 0.9;

  // Geometry Morphing (0.0 = Holo, 1.0 = Quantum)
  double geometryMorph = 0.0;

  // 6D Rotation Parameters (Radians)
  double rotXY = 0.0;
  double rotXZ = 0.0;
  double rotYZ = 0.0;
  double rotXW = 0.0;
  double rotYW = 0.0;
  double rotZW = 0.0;

  // Effects
  double distortion = 0.0;
  double zoom = 0.0;

  // Animation State
  double _time = 0.0;

  void update(double dt) {
    _time += dt * speed;

    // Auto-rotate based on speed/chaos
    if (speed > 0) {
      rotXY += dt * speed * 0.5;
      rotXZ += dt * speed * 0.3;
      rotYZ += dt * speed * 0.2;

      // Higher dimensions rotate more with chaos
      if (chaos > 0.1) {
        rotXW += dt * chaos;
        rotYW += dt * chaos * 0.7;
        rotZW += dt * chaos * 1.3;
      }
    }

    // Pulse distortion
    if (chaos > 0.5) {
      distortion = (distortion + dt * chaos).remainder(1.0); // Simple cycle
    }

    notifyListeners();
  }

  void setParameter(String key, double value) {
    switch (key) {
      case 'chaos': chaos = value; break;
      case 'speed': speed = value; break;
      case 'hue': hue = value; break;
      case 'saturation': saturation = value; break;
      case 'intensity': intensity = value; break;
      case 'geometryMorph': geometryMorph = value; break;
      case 'rotXY': rotXY = value; break;
      case 'rotXZ': rotXZ = value; break;
      case 'rotYZ': rotYZ = value; break;
      case 'rotXW': rotXW = value; break;
      case 'rotYW': rotYW = value; break;
      case 'rotZW': rotZW = value; break;
      case 'distortion': distortion = value; break;
      case 'zoom': zoom = value; break;
    }
    notifyListeners();
  }

  double getParameter(String key) {
    switch (key) {
      case 'chaos': return chaos;
      case 'speed': return speed;
      case 'hue': return hue;
      case 'saturation': return saturation;
      case 'intensity': return intensity;
      case 'geometryMorph': return geometryMorph;
      case 'rotXY': return rotXY;
      case 'rotXZ': return rotXZ;
      case 'rotYZ': return rotYZ;
      case 'rotXW': return rotXW;
      case 'rotYW': return rotYW;
      case 'rotZW': return rotZW;
      case 'distortion': return distortion;
      case 'zoom': return zoom;
      default: return 0.0;
    }
  }

  // Preset Configurations
  void setHolographicMode() {
    geometryMorph = 0.0; // Hard Holo
    saturation = 0.2;
    intensity = 1.0;
    distortion = 0.1;
    hue = 180.0; // Cyan
    notifyListeners();
  }

  void setQuantumMode() {
    geometryMorph = 1.0; // Hard Quantum
    saturation = 0.9;
    intensity = 1.2;
    distortion = 0.3;
    hue = 280.0; // Purple
    notifyListeners();
  }

  // Game Event Reactions
  void onMove() {
    // Slight ripple or flash
    intensity += 0.2;
    Future.delayed(const Duration(milliseconds: 100), () {
      intensity -= 0.2;
      notifyListeners();
    });
    notifyListeners();
  }

  void onCapture(int capturedCount) {
    // Increase chaos based on captured count
    chaos = (capturedCount / 6.0).clamp(0.0, 1.0);
    speed = 1.0 + chaos * 2.0;
    distortion = chaos * 0.5;
    notifyListeners();
  }
}
