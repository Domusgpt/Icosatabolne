# Icosatabolne

A Flutter-based digital version of Abalone with holographic/quantum visualizer effects powered by `vib3codeSDK`.

## Features
- **Full Abalone Game Logic**: Hexagonal grid, Sumito pushing, broadside/inline moves, and precise move validation.
- **Reactive Visualizer**:
  - **Holographic Theme**: Purple/Cyan palette with geometric stability.
  - **Quantum Theme**: Blue/Green palette with chaotic flux.
  - **Dynamic Parameters**: Visuals (chaos, speed, density) react procedurally to game state (winning/losing).
- **Polished UI**: Glassmorphism, vaporwave aesthetics, and responsive layout.
- **Cross-Platform**: Builds for Android and Web.

## Build Outputs

### Android APK (GitHub Actions)
The `Android APK` workflow builds a signed release APK and uploads it as a workflow artifact:
`build/app/outputs/flutter-apk/app-release.apk`.

### Web (GitHub Pages)
The `Deploy Web to Pages` workflow builds the Flutter web bundle and publishes it to GitHub Pages.
Once enabled in repo settings, the site will be available at:
`https://<org-or-user>.github.io/<repo>/`.

## Development
Run tests:
```bash
flutter test
```

Build APK:
```bash
flutter build apk --release
```
