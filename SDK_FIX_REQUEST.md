**Issue Report: Missing C++ Source Files in vib3_flutter SDK**

**Context:**
The Android build for `icosatabolne` is failing because the `vib3_flutter` dependency (branch `claude/project-review-planning-NWnhW`) is missing required C++ source files that are referenced in its `CMakeLists.txt`.

**Symptoms:**
- `flutter build apk` fails with `CMake Error`.
- Error message: `Cannot find source file: geometry/GeometryGenerator.cpp` (and similar for `tests/Vec4_test.cpp`, `tests/Geometry_test.cpp`).

**Evidence:**
A fresh checkout of the branch `claude/project-review-planning-NWnhW` (commit `0602b26d20cd612f231eb1d823614c82a3fd9c1b`) reveals that the `cpp/` directory structure is incomplete.

**Current Content of `cpp/`:**
```
cpp/
├── bindings/
├── include/
├── math/
├── src/
├── build.sh
└── CMakeLists.txt
```

**Missing Content:**
```
cpp/
├── geometry/          <-- MISSING (contains GeometryGenerator.cpp)
└── tests/             <-- MISSING (contains Vec4_test.cpp, Geometry_test.cpp)
```

**Required Action:**
Please ensure that the `geometry/` and `tests/` directories (and their contents) are added and committed to the `claude/project-review-planning-NWnhW` branch in the `vib3codeSDKv3.0.0` repository. Alternatively, modify `cpp/CMakeLists.txt` to remove the build targets `vib3_geometry`, `math_tests`, and `geometry_tests` if these files are not intended to be part of the Flutter SDK build.
