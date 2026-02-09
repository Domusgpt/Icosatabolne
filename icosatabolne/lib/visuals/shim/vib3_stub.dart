// Stub implementation for Web compatibility
// Mirrors the API of vib3_flutter but without FFI

import 'package:flutter/widgets.dart';

enum RotationPlane {
  xy(0), xz(1), yz(2), xw(3), yw(4), zw(5);
  final int value;
  const RotationPlane(this.value);
}

class Vib3Rotation {
  final double xy;
  final double xz;
  final double yz;
  final double xw;
  final double yw;
  final double zw;

  const Vib3Rotation({
    this.xy = 0,
    this.xz = 0,
    this.yz = 0,
    this.xw = 0,
    this.yw = 0,
    this.zw = 0,
  });
}

class Vib3Config {
  final String system;
  final int geometry;
  final int gridDensity;
  final bool audioReactive;
  final double projectionDistance;
  final Vib3Rotation initialRotation;

  const Vib3Config({
    this.system = 'quantum',
    this.geometry = 0,
    this.gridDensity = 32,
    this.audioReactive = false,
    this.projectionDistance = 2.0,
    this.initialRotation = const Vib3Rotation(),
  });
}

class Vib3Engine {
  bool isInitialized = false;
  int? textureId;

  Future<void> initialize(Vib3Config config) async {
    // Stub
    isInitialized = true;
  }

  Future<void> setVisualParams({
    double? morphFactor,
    double? chaos,
    double? speed,
    double? hue,
    double? intensity,
    double? saturation,
  }) async {}

  Future<void> setSystem(String system) async {}
  Future<void> setGeometry(int index) async {}
  Future<void> startRendering() async {}
  Future<void> stopRendering() async {}

  void dispose() {}
}

class Vib3View extends StatelessWidget {
  final Vib3Engine engine;

  const Vib3View({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    // This should not be rendered on web if Vib3Adapter is working correctly (fallback mode),
    // but if it is, we show a placeholder.
    return const SizedBox.shrink();
  }
}
