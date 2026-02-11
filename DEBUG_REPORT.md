# Native Integration Debug Report

## Issue Diagnosis
The user reported a "black screen" on Android release builds. This typically indicates one of two issues in Flutter apps utilizing native C++ plugins via `Texture` widgets:
1.  **Missing Native Library (`.so`):** The shared object library was not packaged into the APK, or was stripped during the release build process.
2.  **Symbol Stripping:** ProGuard/R8 aggressively removed the JNI hooks or FFI bridge classes, preventing the Dart code from calling into the native layer.
3.  **Initialization Deadlock/Failure:** The native `initialize()` call hangs or returns an invalid texture ID (0), causing the Flutter `Texture` widget to render nothing (transparent/black).

## Findings
*   **Native Library Name:** `libvib3_core.so` (Android).
*   **FFI Bindings:** `vib3codeSDK/flutter/lib/src/ffi/vib3_ffi.dart` uses `DynamicLibrary.open('libvib3_core.so')`.
*   **Build Config:** The `CMakeLists.txt` correctly defines a `SHARED` library named `vib3_core`.
*   **Missing Submodules:** CI logs showed warnings about missing submodules (`vib3codeSDK`). This was fixed in previous steps by switching to a `git` dependency with a specific ref, but potential artifact caching issues or ProGuard stripping remained risks.

## Fixes Implemented

### 1. Robust Fallback Rendering
*   **Change:** Wrapped the `Texture` widget in a `Stack`.
*   **Benefit:** A `FallbackPainter` (CustomPaint) is now rendered *behind* the native texture. If the native texture fails to initialize, renders as transparent, or hangs, the user will see the fallback visuals instead of a black void.
*   **Location:** `icosatabolne/lib/glyph_war/ui/glyph_visuals.dart`.

### 2. Initialization Safety
*   **Change:** Added a 5-second timeout to the native `initialize()` call.
*   **Benefit:** Prevents the app from hanging indefinitely on the splash screen if the native engine deadlocks.
*   **Location:** `GlyphVisualController.initialize`.

### 3. ProGuard / R8 Configuration
*   **Change:** Enabled minification (`isMinifyEnabled = true`) but added explicit `keep` rules.
*   **Rules:**
    ```proguard
    -keep class com.vib3.flutter.** { *; }
    -keep class com.vib3.engine.** { *; }
    -keepclasseswithmembernames class * {
        native <methods>;
    }
    ```
*   **Benefit:** Ensures that the Java/Kotlin wrapper classes and JNI methods required for the FFI bridge are not stripped by the R8 compiler during release builds.
*   **Location:** `icosatabolne/android/app/proguard-rules.pro` and `build.gradle.kts`.

## Verification
*   **CI/CD:** The GitHub Actions workflow (`.github/workflows/deploy.yml`) builds the Android APK with these new configurations.
*   **Manual Deployment:** The user can trigger this workflow manually via `workflow_dispatch`.

## Recommendation for User
If the screen remains black even with the FallbackPainter:
1.  The issue might be unrelated to the native engine (e.g., the entire Flutter view is not attaching).
2.  However, the `FallbackPainter` is pure Dart/Flutter code, so if the app launches at all, it *should* render.
3.  Ensure the device supports OpenGL ES versions required by the Flutter engine.
