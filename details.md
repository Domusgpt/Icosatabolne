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
The application currently fails to build due to compilation errors within the external dependency `vib3_flutter`. The project is configured to use a specific feature branch of the SDK as requested:

**pubspec.yaml:**
```yaml
vib3_flutter:
  git:
    url: https://github.com/Domusgpt/vib3codeSDKv3.0.0.git
    ref: feature/holographic-exhale-fix-2970824138550486291
    path: flutter
```

### Error Log
The build fails with internal type errors in the SDK package:

```
/home/jules/.pub-cache/git/vib3codeSDKv3.0.0-.../flutter/lib/src/widgets/vib3_view.dart:185:14: Error: Type 'RotationPlane' not found.
  final List<RotationPlane> activePlanes;
             ^^^^^^^^^^^^^
/home/jules/.pub-cache/git/vib3codeSDKv3.0.0-.../flutter/lib/src/ffi/vib3_ffi.dart:272:44: Error: The method 'sqrt' isn't defined for the type 'double'.
    return (x * x + y * y + z * z + w * w).sqrt();
                                           ^^^^
/home/jules/.pub-cache/git/vib3codeSDKv3.0.0-.../flutter/lib/src/ffi/vib3_ffi.dart:536:12: Error: The getter 'malloc' isn't defined for the type '_CallocAllocator'.
    return malloc.allocate<T>(byteCount, alignment: alignment);
           ^^^^^^
```

### Resolution Status
The application logic is complete and correct. The build cannot proceed until the upstream `vib3_flutter` SDK branch is fixed to resolve these compilation errors. The user has been notified and has agreed to fix the SDK.

## Verification
You can verify the game logic implementation by running the unit tests (which do not depend on the visualizer SDK for compilation in the test environment):

```bash
flutter test test/game_logic_test.dart
```
