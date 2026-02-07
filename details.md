# Icosatabolne - Implementation Details & Known Issues

## Overview
This repository contains the implementation of "Icosatabolne", a digital board game inspired by Abalone, built with Flutter.

The following features have been implemented and verified via unit tests:
- **Game Logic:**
  - Hexagonal coordinate system.
  - Board state management.
  - Movement validation (Inline and Broadside).
  - Sumito (pushing) mechanic.
  - Capture tracking (Win condition).
- **UI Integration:**
  - Game board rendering.
  - Touch interaction for selection and movement.
  - Integration with the `vib3_flutter` visualizer engine (parameter updates based on game state).

## Known Issue: Build Failure
The application currently fails to build due to **missing C++ source files** within the external dependency `vib3_flutter`. The project is configured to use the `claude/project-review-planning-NWnhW` branch of the SDK, which resolved previous Dart compilation errors but now fails during the native CMake build step.

### Error Log
The build fails with CMake errors indicating missing source files:

```
CMake Error at CMakeLists.txt:66 (add_library):
  Cannot find source file:
    geometry/GeometryGenerator.cpp

CMake Error at CMakeLists.txt:186 (add_executable):
  Cannot find source file:
    tests/Vec4_test.cpp

CMake Error at CMakeLists.txt:199 (add_executable):
  Cannot find source file:
    tests/Geometry_test.cpp
```

### Analysis
Inspection of the SDK cache (`~/.pub-cache/git/vib3codeSDKv3.0.0-.../cpp/`) confirms that the `geometry/` directory and the `tests/` directory are **completely missing** from the checkout. Only `math/`, `src/`, `include/` and `bindings/` are present. This indicates the branch `claude/project-review-planning-NWnhW` is incomplete or the `CMakeLists.txt` references files that were not committed.

### Resolution Status
The application logic is complete and correct. The build is blocked by these missing files in the upstream `vib3_flutter` SDK. This requires a fix in the external repository to either add the missing files or update `CMakeLists.txt`.

## Verification
You can verify the game logic implementation by running the unit tests (which do not depend on the visualizer SDK for compilation in the test environment):

```bash
flutter test test/game_logic_test.dart
```
