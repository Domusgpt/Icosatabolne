import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icosatabolne/game/game_controller.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/ui/board_widget.dart';
import 'package:icosatabolne/visuals/visual_effects_layer.dart';
import 'package:icosatabolne/visuals/vib3_shim.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Vib3Engine? _quantumEngine;
  Vib3Engine? _holographicEngine;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initEngines());
  }

  Future<void> _initEngines() async {
    // On Web or Desktop (non-mobile), we might just skip this or let the shim handle it.
    // The shim is safe, so we can just initialize.
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !isMobile) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      _quantumEngine = Vib3Engine();
      await _quantumEngine!.initialize(const Vib3Config(
        system: 'quantum',
        geometry: 8,
        gridDensity: 32,
      ));
      await _quantumEngine!.setVisualParams(hue: 200, saturation: 0.8, intensity: 0.9);
      await _quantumEngine!.startRendering();

      _holographicEngine = Vib3Engine();
      await _holographicEngine!.initialize(const Vib3Config(
        system: 'holographic',
        geometry: 0,
        gridDensity: 32,
      ));
      await _holographicEngine!.setVisualParams(hue: 180, saturation: 0.8, intensity: 0.9);
      await _holographicEngine!.startRendering();
    } catch (e) {
      debugPrint("Failed to initialize shared engines: $e");
      // Fallback to null engines (Marbles will try to create their own or fail gracefully)
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantumEngine?.stopRendering();
    _quantumEngine?.dispose();
    _holographicEngine?.stopRendering();
    _holographicEngine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: Scaffold(
        backgroundColor: Colors.black, // Vaporwave dark
        body: Stack(
          children: [
            // Background effects
            const _BackgroundEffects(),

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
                          final controller = context.watch<GameController>();
                          return VisualEffectsLayer(
                            chaos: controller.chaosLevel,
                            intensity: controller.speedLevel,
                            child: BoardWidget(
                              size: size * 0.9,
                              quantumEngine: _quantumEngine,
                              holographicEngine: _holographicEngine,
                            ),
                          );
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
          ],
        ),
      ),
    );
  }
}

class _BackgroundEffects extends StatelessWidget {
  const _BackgroundEffects();

  @override
  Widget build(BuildContext context) {
    // Vaporwave gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0221), // Deep purple
            Color(0xFF2E0249),
            Color(0xFF0F3460), // Cyber blue
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
    .shimmer(duration: 5.seconds, color: Colors.purpleAccent.withOpacity(0.1));
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
