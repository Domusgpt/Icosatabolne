# Icosatabolne

A Flutter-based digital version of Abalone with holographic/quantum visualizer effects powered by `vib3codeSDK`.

## Status
**Blocked:** The Android build is currently failing due to missing C++ source files in the `vib3_flutter` SDK dependency.
- **Missing Files:** `geometry/GeometryGenerator.cpp`, `tests/Vec4_test.cpp`, `tests/Geometry_test.cpp`.
- **Impact:** `flutter build apk` fails with `CMake Error`.
- **Workaround:** The project code (Dart) is complete and verified with `flutter test`. UI logic is fully implemented.

## Features
- Full Abalone game logic (Hexagonal grid, Sumito pushing, broadside/inline moves).
- Reactive Visualizer Integration:
  - Holographic vs Quantum player themes.
  - Dynamic shader parameters (chaos, speed, density) based on game state (winning/losing).
- Polished UI with glassmorphism and vaporwave aesthetics.

## Development
Run tests:
```bash
flutter test
```
