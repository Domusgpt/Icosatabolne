# SDK Debug Report: vib3codeSDK Integration Failure

**Date:** Oct 24, 2023
**Status:** Blocked (Native Android/iOS)
**Component:** `vib3codeSDK` (C++ Core)

## Issue Description
The native build for the `icosatabolne` application is failing during the CMake configuration phase. The failure is due to missing source directories referenced in the provided `CMakeLists.txt`.

## Detailed Findings

1.  **CMake Configuration:**
    The file `icosatabolne/cpp/CMakeLists.txt` defines a library target `vib3_geometry` starting at line 66:
    ```cmake
    add_library(vib3_geometry STATIC
        geometry/GeometryGenerator.cpp
        geometry/Tesseract.cpp
        geometry/Tetrahedron.cpp
        geometry/Sphere.cpp
        ...
    )
    ```
    It also defines tests in `tests/` directory (e.g., `tests/Vec4_test.cpp`).

2.  **File System Reality:**
    The vendored SDK directory `icosatabolne/cpp` **does not contain** the `geometry` or `tests` directories.
    *   **Exists:** `math/`, `src/`, `include/`, `bindings/`
    *   **Missing:** `geometry/`, `tests/`

## Impact
*   **Android/iOS:** Cannot build the native shared library (`libvib3_core.so` / `vib3_core.framework`).
*   **Web:** Working via fallback painter, but lacks full native performance/features intended by the SDK.
*   **Game Logic:** The game relies on `Sphere.cpp` logic (presumably) for the ball geometry. Without the `vib3_geometry` library, we cannot instantiate the native sphere objects.

## Resolution Required
Please provide the full source tree including `geometry/` and `tests/`, or update `CMakeLists.txt` to reflect the partial distribution.

## Temporary Workaround (Attempted)
We are patching `CMakeLists.txt` to exclude the missing components so that at least the `vib3_math` and `vib3_bindings` can compile.
