import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/ui/board_widget.dart';
import 'package:icosatabolne/ui/visualizer_debug_panel.dart';
import 'package:icosatabolne/visuals/visualizer_controller.dart';
import 'package:icosatabolne/visuals/visualizer_choreographer.dart';
import 'package:icosatabolne/visuals/vib3_adapter.dart';
import 'package:icosatabolne/visuals/game_config.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late VisualizerController _vizController;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _vizController = VisualizerController();

    // Ticker to drive the visualizer physics (decay, smooth transitions)
    _ticker = createTicker((elapsed) {
      // Assuming 60fps roughly, or use elapsed.
      // VisualizerController uses a fixed dt logic mostly for damping
      _vizController.update(0.016);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _vizController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameController()),
        ChangeNotifierProvider.value(value: _vizController),
      ],
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatefulWidget {
  const _GameScreenContent();

  @override
  State<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<_GameScreenContent> with TickerProviderStateMixin {
  VisualizerChoreographer? _choreographer;

  @override
  void initState() {
    super.initState();
    // Hook up game events to visualizer via Choreographer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameController>();
      final viz = context.read<VisualizerController>();

      // Initialize Choreographer which handles all reactive logic
      _choreographer = VisualizerChoreographer(
        visualizer: viz,
        game: game,
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    _choreographer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Vaporwave dark
      body: Stack(
        children: [
          // Background effects (Vib3 Visualizer)
          const Positioned.fill(child: _Vib3Background()),

          // Main UI
          SafeArea(
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double size = min(constraints.maxWidth, constraints.maxHeight);
                        return BoardWidget(size: size * 0.9);
                      },
                    ),
                  ),
                ),
                const _ScorePanel(),
              ],
            ),
          ),

          // Moiré Overlay
          const _MoireOverlay(),

          // Game Over Overlay
          const _GameOverOverlay(),

          // Visualizer Debug Panel (Top Layer)
          const VisualizerDebugPanel(),
        ],
      ),
    );
  }
}

class _Vib3Background extends StatelessWidget {
  const _Vib3Background();

  @override
  Widget build(BuildContext context) {
    final viz = context.watch<VisualizerController>();

    return Vib3Adapter(
      config: const GameVib3Config(
        system: 'background',
        geometry: 0,
        gridDensity: 16
      ),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      chaos: viz.chaos,
      speed: viz.speed,
      hue: viz.hue,
      saturation: viz.saturation,
      intensity: viz.intensity,
      geometryMorph: viz.geometryMorph,
      rotXY: viz.rotXY,
      rotXZ: viz.rotXZ,
      rotYZ: viz.rotYZ,
      rotXW: viz.rotXW,
      rotYW: viz.rotYW,
      rotZW: viz.rotZW,
      distortion: viz.distortion,
      zoom: viz.zoom,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final turn = controller.currentTurn;
    final turnColor = turn == Player.holographic ? Colors.cyanAccent : Colors.purpleAccent;
    final turnName = turn == Player.holographic ? "HOLOGRAPHIC" : "QUANTUM";

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "ICOSATABOLNE",
            style: TextStyle(
              fontFamily: 'Courier', // Monospace for terminal vibe
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.cyan, blurRadius: 10),
                Shadow(color: Colors.purpleAccent, blurRadius: 5, offset: Offset(2, 0)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: turnColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: turnColor.withOpacity(0.2), blurRadius: 20),
              ],
            ),
            child: Text(
              "TURN: $turnName",
              style: TextStyle(color: turnColor, fontWeight: FontWeight.bold),
            ),
          ).animate(key: ValueKey(turn))
           .fadeIn().scale().shimmer(color: turnColor),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final holoScore = controller.capturedMarbles[Player.holographic] ?? 0;
    final quantScore = controller.capturedMarbles[Player.quantum] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreCard("HOLO", holoScore, Colors.cyanAccent),
          _ScoreCard("QUANTUM", quantScore, Colors.purpleAccent),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreCard(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7))),
        Text(
          "$score / 6",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ).animate(key: ValueKey(score)).scale(duration: 300.ms, curve: Curves.elasticOut),
      ],
    );
  }
}

class _MoireOverlay extends StatelessWidget {
  const _MoireOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _MoirePainter(),
      ),
    );
  }
}

class _MoirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw fine lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    if (!controller.isGameOver) return const SizedBox.shrink();

    final winner = controller.winner!;
    final color = winner == Player.holographic ? Colors.cyanAccent : Colors.purpleAccent;
    final name = winner == Player.holographic ? "HOLOGRAPHIC" : "QUANTUM";

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$name WINS",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(color: color, blurRadius: 20),
                  const Shadow(color: Colors.white, blurRadius: 5),
                ],
              ),
            ).animate().scale(duration: 500.ms).shimmer(duration: 1.seconds),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.2),
                foregroundColor: color,
                side: BorderSide(color: color),
              ),
              child: const Text("REBOOT SYSTEM"),
            ),
          ],
        ),
      ),
    );
  }
}
