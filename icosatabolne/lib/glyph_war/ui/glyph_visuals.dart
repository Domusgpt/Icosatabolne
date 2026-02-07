import 'package:flutter/material.dart';
import 'package:vib3_flutter/vib3_flutter.dart';
import '../game_logic.dart';

// Parameter Mapping Logic (Same as before)
class VisualizerParams {
  final double chaos;
  final double speed;
  final double hue;
  final double saturation;
  final double intensity;

  VisualizerParams({
    required this.chaos,
    required this.speed,
    required this.hue,
    required this.saturation,
    required this.intensity,
  });
}

class GlyphVisuals {
  // ... (Same mapping logic, repeated for brevity)
  static VisualizerParams getBoardParams(GlyphWarController game) {
    double chaos = game.tension * 0.3;
    double speed = 0.2 + (game.tension * 0.3);
    return VisualizerParams(
      chaos: chaos,
      speed: speed,
      hue: 220,
      saturation: 0.5,
      intensity: 0.4,
    );
  }

  static VisualizerParams getGlyphParams(GlyphWarController game) {
    double chaos = 0.4 + (game.tension * 0.6);
    double speed = 0.8 + (game.tension * 1.5);
    double hue = 280.0;
    if (game.phase == GlyphWarPhase.attack) {
      hue = 0.0;
      if (game.attackTimeRemaining <= 3) {
        chaos = 1.0;
      }
    }
    return VisualizerParams(
      chaos: chaos,
      speed: speed,
      hue: hue,
      saturation: 0.9,
      intensity: 1.0,
    );
  }

  static VisualizerParams getBezelParams(GlyphWarController game) {
    double chaos = game.phase == GlyphWarPhase.attack ? 0.5 : 0.1;
    double speed = game.phase == GlyphWarPhase.attack ? 2.0 : 0.5;
    double hue = game.player1.isAttacking ? 180.0 : (game.player2.isAttacking ? 300.0 : 180.0);
    return VisualizerParams(
      chaos: chaos,
      speed: speed,
      hue: hue,
      saturation: 0.8,
      intensity: 0.8,
    );
  }
}

// Configs
final kBoardConfig = const Vib3Config(
  system: 'holographic',
  geometry: 6,
  projectionDistance: 3.0,
);

final kGlyphConfig = const Vib3Config(
  system: 'quantum',
  geometry: 15,
  projectionDistance: 1.5,
);

final kBezelConfig = const Vib3Config(
  system: 'faceted',
  geometry: 3,
  gridDensity: 16,
);

class GlyphVisualController extends ChangeNotifier {
  final Vib3Engine boardEngine = Vib3Engine();
  final Vib3Engine glyphEngine = Vib3Engine();
  final Vib3Engine bezelEngine = Vib3Engine();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    await Future.wait([
      boardEngine.initialize(kBoardConfig),
      glyphEngine.initialize(kGlyphConfig),
      bezelEngine.initialize(kBezelConfig),
    ]);

    await Future.wait([
      boardEngine.startRendering(),
      glyphEngine.startRendering(),
      bezelEngine.startRendering(),
    ]);

    _initialized = true;
    notifyListeners();
  }

  void update(GlyphWarController game) {
    if (!_initialized) return;

    final boardParams = GlyphVisuals.getBoardParams(game);
    final glyphParams = GlyphVisuals.getGlyphParams(game);
    final bezelParams = GlyphVisuals.getBezelParams(game);

    boardEngine.setVisualParams(
      chaos: boardParams.chaos,
      speed: boardParams.speed,
      hue: boardParams.hue,
      saturation: boardParams.saturation,
      intensity: boardParams.intensity,
    );

    glyphEngine.setVisualParams(
      chaos: glyphParams.chaos,
      speed: glyphParams.speed,
      hue: glyphParams.hue,
      saturation: glyphParams.saturation,
      intensity: glyphParams.intensity,
    );

    bezelEngine.setVisualParams(
      chaos: bezelParams.chaos,
      speed: bezelParams.speed,
      hue: bezelParams.hue,
      saturation: bezelParams.saturation,
      intensity: bezelParams.intensity,
    );
  }

  @override
  void dispose() {
    boardEngine.dispose();
    glyphEngine.dispose();
    bezelEngine.dispose();
    super.dispose();
  }
}

class SharedVisualizerWidget extends StatelessWidget {
  final Vib3Engine engine;
  final BoxFit fit;
  final Alignment alignment;

  const SharedVisualizerWidget({
    super.key,
    required this.engine,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (!engine.isInitialized || engine.textureId == null) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        child: SizedBox(
          width: 100, // Texture size doesn't matter for FittedBox, aspect ratio matters?
          height: 100, // Assuming square texture from engine
          child: Texture(textureId: engine.textureId!),
        ),
      ),
    );
  }
}
