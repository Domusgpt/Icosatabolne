import 'dart:async';
import 'dart:math';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/game/game_events.dart';
import 'package:icosatabolne/visuals/visualizer_controller.dart';

class VisualizerChoreographer {
  final VisualizerController visualizer;
  final GameController game;
  final TickerProvider vsync;

  // Effect Controllers
  late final AnimationController _impactController;
  late final AnimationController _flashController;
  late final AnimationController _twistController;
  late final AnimationController _scanlineController;

  // State tracking
  StreamSubscription? _eventSub;
  double _baseChaos = 0.0;
  double _baseHue = 200.0;
  double _baseDistortion = 0.0;

  VisualizerChoreographer({
    required this.visualizer,
    required this.game,
    required this.vsync,
  }) {
    _initControllers();
    _listenToGame();
    // Initial sync
    _updateBaseState();
  }

  void _initControllers() {
    _impactController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );

    _flashController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );

    _twistController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );

    _scanlineController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2000),
    )..repeat(); // Continuous subtle effect

    // Drive visualizer from animations
    _impactController.addListener(() {
      double val = Curves.elasticOut.transform(_impactController.value);
      // Combine base distortion with impact
      visualizer.distortion = _baseDistortion + (val * 0.8);
      // Also affect zoom slightly
      visualizer.zoom = (val * 0.1);
      visualizer.notifyListeners();
    });

    _flashController.addListener(() {
      double val = Curves.easeOutQuad.transform(_flashController.value);
      // Flash intensity adds to base
      visualizer.intensity = 1.0 + (val * 1.5);
      // Saturation drops on flash (bleach effect)
      visualizer.saturation = 0.8 - (val * 0.8);
      visualizer.notifyListeners();
    });

    _twistController.addListener(() {
       double val = Curves.easeInOutCubic.transform(_twistController.value);
       // Add twist to base rotation? Or just spin?
       // Let's just set the ZW rotation offset
       visualizer.rotZW = val * pi;
       visualizer.notifyListeners();
    });

    _scanlineController.addListener(() {
       // Subtle scanline breathing on rotYW
       if (visualizer.chaos < 0.1) {
          visualizer.rotYW = sin(_scanlineController.value * pi * 2) * 0.1;
          visualizer.notifyListeners();
       }
    });
  }

  void dispose() {
    _eventSub?.cancel();
    game.removeListener(_updateBaseState);
    _impactController.dispose();
    _flashController.dispose();
    _twistController.dispose();
    _scanlineController.dispose();
  }

  void _listenToGame() {
    _eventSub = game.events.listen((event) {
      if (event is MoveEvent) {
        _onMove(event);
      } else if (event is PushEvent) {
        _onPush(event);
      } else if (event is CaptureEvent) {
        _onCapture(event);
      } else if (event is GameOverEvent) {
        _onGameOver(event);
      } else if (event is GameResetEvent) {
        _onReset();
      }
    });

    game.addListener(_updateBaseState);
  }

  void _updateBaseState() {
    int holoLost = game.capturedMarbles[Player.holographic] ?? 0;
    int quantLost = game.capturedMarbles[Player.quantum] ?? 0;
    int totalLost = holoLost + quantLost;

    // Tension Calculation
    double tension = (totalLost / 10.0).clamp(0.0, 1.0);
    _baseChaos = tension;
    _baseDistortion = tension * 0.3; // Base distortion increases with tension

    // Apply Base Values (if not animating)
    if (!_impactController.isAnimating) {
      visualizer.distortion = _baseDistortion;
    }
    visualizer.chaos = _baseChaos;
    visualizer.speed = 1.0 + (tension * 3.0);

    // Color Logic
    if (holoLost > quantLost) {
      _baseHue = 180.0 * (1.0 - (holoLost / 7.0));
    } else if (quantLost > holoLost) {
      _baseHue = 280.0 + (80.0 * (quantLost / 7.0));
    } else {
      _baseHue = 230.0;
    }
    visualizer.hue = _baseHue;

    visualizer.notifyListeners();
  }

  void _onMove(MoveEvent event) {
    // Quick Ripple
    // 0 -> 1 -> 0 over 300ms
    _impactController.duration = const Duration(milliseconds: 300);
    _impactController.forward(from: 0.0).then((_) => _impactController.reverse());

    // Slight Hue Shift based on player
    double shift = event.player == Player.holographic ? -20 : 20;
    visualizer.hue = (_baseHue + shift) % 360;
  }

  void _onPush(PushEvent event) {
    // "Crunch" - Harder Impact
    _impactController.duration = const Duration(milliseconds: 500);
    _impactController.forward(from: 0.0).then((_) => _impactController.reverse());

    // Twist
    _twistController.forward(from: 0.0).then((_) => _twistController.reverse());

    // Color Invert
    visualizer.hue = (_baseHue + 180) % 360;
  }

  void _onCapture(CaptureEvent event) {
    // Explosion
    _flashController.forward(from: 0.0).then((_) => _flashController.reverse());

    // Freeze frame effect? (Stop time briefly)
    double oldSpeed = visualizer.speed;
    visualizer.speed = 0.0;
    Future.delayed(const Duration(milliseconds: 100), () {
      visualizer.speed = oldSpeed;
    });
  }

  void _onGameOver(GameOverEvent event) {
    visualizer.chaos = 1.0;
    visualizer.speed = 0.2; // Matrix bullet time
    visualizer.distortion = 2.0;
    visualizer.hue = event.winner == Player.holographic ? 180.0 : 280.0;
    visualizer.notifyListeners();
  }

  void _onReset() {
    _baseChaos = 0.0;
    _baseDistortion = 0.0;
    visualizer.chaos = 0.0;
    visualizer.speed = 1.0;
    visualizer.distortion = 0.0;
    visualizer.hue = 200.0;
    visualizer.intensity = 1.0;
    visualizer.notifyListeners();
  }
}
