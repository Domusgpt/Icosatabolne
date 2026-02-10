import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vib3_flutter/vib3_flutter.dart';

void main() {
  runApp(const AbaloneVib3App());
}

enum PlayerSide { holographic, quantum }

enum MarbleState { empty, holographic, quantum }

class AbaloneVib3App extends StatelessWidget {
  const AbaloneVib3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Icosatabolne',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF09060F),
      ),
      home: const AbaloneHome(),
    );
  }
}

class AbaloneHome extends StatefulWidget {
  const AbaloneHome({super.key});

  @override
  State<AbaloneHome> createState() => _AbaloneHomeState();
}

class _AbaloneHomeState extends State<AbaloneHome>
    with TickerProviderStateMixin {
  final _gameState = GameState.initial();
  late final AnimationController _pulseController;
  late final Vib3Engine _holoEngine;
  late final Vib3Engine _quantumEngine;
  bool _holoReady = false;
  bool _quantumReady = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    _holoEngine = Vib3Engine();
    _quantumEngine = Vib3Engine();
    _initializeEngines();
  }

  Future<void> _initializeEngines() async {
    if (!mounted) return;
    if (kIsWeb) return;
    await _initializeEngine(
      _holoEngine,
      const Vib3Config(system: 'holographic', geometry: 9, gridDensity: 48),
      (value) => setState(() => _holoReady = value),
    );
    await _initializeEngine(
      _quantumEngine,
      const Vib3Config(system: 'quantum', geometry: 12, gridDensity: 48),
      (value) => setState(() => _quantumReady = value),
    );
  }

  Future<void> _initializeEngine(
    Vib3Engine engine,
    Vib3Config config,
    ValueChanged<bool> onReady,
  ) async {
    try {
      await engine.initialize(config);
      await engine.setVisualParams(
        morphFactor: 0.6,
        chaos: 0.2,
        speed: 0.8,
        hue: config.system == 'holographic' ? 290 : 200,
        intensity: 0.9,
        saturation: 0.8,
      );
      await engine.startRendering();
      onReady(true);
    } catch (_) {
      onReady(false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holoEngine.dispose();
    _quantumEngine.dispose();
    super.dispose();
  }

  void _onTap(BoardSlot slot) {
    setState(() {
      _gameState.toggleSlot(slot);
      _gameState.advanceTurn();
    });

    final hapticStrength = _gameState.currentPlayer == PlayerSide.holographic
        ? HapticFeedback.lightImpact
        : HapticFeedback.mediumImpact;
    hapticStrength();

    _syncEngines();
  }

  void _syncEngines() {
    final holoParams = _gameState.visualParamsFor(PlayerSide.holographic);
    final quantumParams = _gameState.visualParamsFor(PlayerSide.quantum);

    if (_holoEngine.isInitialized) {
      _holoEngine.setVisualParams(
        morphFactor: holoParams.morph,
        chaos: holoParams.chaos,
        speed: holoParams.speed,
        hue: holoParams.hue,
        intensity: holoParams.intensity,
        saturation: holoParams.saturation,
      );
      _holoEngine.setRotation(holoParams.rotation);
      _holoEngine.setGeometry(holoParams.geometry);
    }

    if (_quantumEngine.isInitialized) {
      _quantumEngine.setVisualParams(
        morphFactor: quantumParams.morph,
        chaos: quantumParams.chaos,
        speed: quantumParams.speed,
        hue: quantumParams.hue,
        intensity: quantumParams.intensity,
        saturation: quantumParams.saturation,
      );
      _quantumEngine.setRotation(quantumParams.rotation);
      _quantumEngine.setGeometry(quantumParams.geometry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardState = _gameState;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const VaporwaveBackdrop(),
            Column(
              children: [
                HeaderPanel(
                  currentPlayer: boardState.currentPlayer,
                  holoScore: boardState.holoCount,
                  quantumScore: boardState.quantumCount,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: VisualizerPanel(
                          title: 'Holographic',
                          palette: const [
                            Color(0xFF8E4DFF),
                            Color(0xFF36F9F6),
                            Color(0xFFFF8BF5),
                          ],
                          engine: _holoEngine,
                          isReady: _holoReady,
                          pulse: _pulseController,
                          params: boardState
                              .visualParamsFor(PlayerSide.holographic),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: BoardPanel(
                          slots: boardState.slots,
                          onTap: _onTap,
                          pulse: _pulseController,
                          activePlayer: boardState.currentPlayer,
                        ),
                      ),
                      Expanded(
                        child: VisualizerPanel(
                          title: 'Quantum',
                          palette: const [
                            Color(0xFF2A9DF4),
                            Color(0xFF00FFC6),
                            Color(0xFF58C5FF),
                          ],
                          engine: _quantumEngine,
                          isReady: _quantumReady,
                          pulse: _pulseController,
                          params: boardState
                              .visualParamsFor(PlayerSide.quantum),
                        ),
                      ),
                    ],
                  ),
                ),
                FooterPanel(
                  activePlayer: boardState.currentPlayer,
                  holoCount: boardState.holoCount,
                  quantumCount: boardState.quantumCount,
                ),
              ],
            ),
            const ChromaticAberrationOverlay(),
          ],
        ),
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    super.key,
    required this.currentPlayer,
    required this.holoScore,
    required this.quantumScore,
  });

  final PlayerSide currentPlayer;
  final int holoScore;
  final int quantumScore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: GlassPanel(
        child: Row(
          children: [
            Expanded(
              child: PlayerCard(
                title: 'Holographic',
                score: holoScore,
                isActive: currentPlayer == PlayerSide.holographic,
                accent: const Color(0xFF8E4DFF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PlayerCard(
                title: 'Quantum',
                score: quantumScore,
                isActive: currentPlayer == PlayerSide.quantum,
                accent: const Color(0xFF2A9DF4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.title,
    required this.score,
    required this.isActive,
    required this.accent,
  });

  final String title;
  final int score;
  final bool isActive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? accent : Colors.white24,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(isActive ? 0.5 : 0.2),
            blurRadius: isActive ? 24 : 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent, Colors.white],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.7),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            score.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class BoardPanel extends StatelessWidget {
  const BoardPanel({
    super.key,
    required this.slots,
    required this.onTap,
    required this.pulse,
    required this.activePlayer,
  });

  final List<BoardSlot> slots;
  final ValueChanged<BoardSlot> onTap;
  final Animation<double> pulse;
  final PlayerSide activePlayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          return GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 540,
              height: 480,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF291C3B),
                    const Color(0xFF0B0713),
                  ],
                  radius: 0.9,
                  center: Alignment(0, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: BoardGlowPainter(pulse.value),
                  ),
                  ...slots.map(
                    (slot) => Positioned(
                      left: slot.position.dx,
                      top: slot.position.dy,
                      child: MarbleWidget(
                        slot: slot,
                        pulse: pulse.value,
                        onTap: () => onTap(slot),
                        isActive: slot.owner == activePlayer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MarbleWidget extends StatelessWidget {
  const MarbleWidget({
    super.key,
    required this.slot,
    required this.pulse,
    required this.onTap,
    required this.isActive,
  });

  final BoardSlot slot;
  final double pulse;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = slot.owner == MarbleState.holographic
        ? const [Color(0xFFB06DFF), Color(0xFF4DF3FF)]
        : slot.owner == MarbleState.quantum
            ? const [Color(0xFF39B6FF), Color(0xFF00FFD1)]
            : const [Color(0xFF3D3651), Color(0xFF14111E)];
    final glow = slot.owner == MarbleState.empty
        ? Colors.white24
        : palette.first.withOpacity(0.8);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(isActive ? 0.9 : 0.5),
              blurRadius: isActive ? 18 + pulse * 10 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: palette,
                    radius: 0.9,
                    center: Alignment(0.2, -0.2),
                  ),
                ),
              ),
              Opacity(
                opacity: 0.6,
                child: CustomPaint(
                  painter: MarbleShaderPainter(
                    seed: slot.seed,
                    pulse: pulse,
                    isEmpty: slot.owner == MarbleState.empty,
                  ),
                ),
              ),
              if (slot.owner != MarbleState.empty)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisualizerPanel extends StatelessWidget {
  const VisualizerPanel({
    super.key,
    required this.title,
    required this.palette,
    required this.engine,
    required this.isReady,
    required this.pulse,
    required this.params,
  });

  final String title;
  final List<Color> palette;
  final Vib3Engine engine;
  final bool isReady;
  final Animation<double> pulse;
  final VisualizerParams params;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.first,
                    boxShadow: [
                      BoxShadow(
                        color: palette.first.withOpacity(0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.6,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          palette.first.withOpacity(0.35),
                          palette.last.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: palette.first.withOpacity(0.6),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (isReady)
                          Vib3View(engine: engine)
                        else
                          PlaceholderShader(
                            palette: palette,
                            pulse: pulse.value,
                            params: params,
                          ),
                        Positioned(
                          left: 16,
                          bottom: 16,
                          right: 16,
                          child: ShaderStats(params: params),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShaderStats extends StatelessWidget {
  const ShaderStats({super.key, required this.params});

  final VisualizerParams params;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: 'Density', value: params.density.toStringAsFixed(2)),
          _StatItem(label: 'Chaos', value: params.chaos.toStringAsFixed(2)),
          _StatItem(label: 'Speed', value: params.speed.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class PlaceholderShader extends StatelessWidget {
  const PlaceholderShader({
    super.key,
    required this.palette,
    required this.pulse,
    required this.params,
  });

  final List<Color> palette;
  final double pulse;
  final VisualizerParams params;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PlaceholderShaderPainter(
        colors: palette,
        pulse: pulse,
        params: params,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class FooterPanel extends StatelessWidget {
  const FooterPanel({
    super.key,
    required this.activePlayer,
    required this.holoCount,
    required this.quantumCount,
  });

  final PlayerSide activePlayer;
  final int holoCount;
  final int quantumCount;

  @override
  Widget build(BuildContext context) {
    final hint = activePlayer == PlayerSide.holographic
        ? 'Holographic surge: push or flank'
        : 'Quantum alignment: destabilize the flank';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.blur_on, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      letterSpacing: 1.1,
                    ),
              ),
            ),
            Text(
              'H:$holoCount  Q:$quantumCount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class VaporwaveBackdrop extends StatelessWidget {
  const VaporwaveBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0814),
            Color(0xFF180C2B),
            Color(0xFF2E1244),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: VaporwaveGridPainter(),
      ),
    );
  }
}

class ChromaticAberrationOverlay extends StatelessWidget {
  const ChromaticAberrationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.25,
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionalTranslation(
                translation: const Offset(-0.004, 0),
                child: Container(color: Colors.redAccent.withOpacity(0.15)),
              ),
            ),
            Positioned.fill(
              child: FractionalTranslation(
                translation: const Offset(0.004, 0),
                child: Container(color: Colors.blueAccent.withOpacity(0.15)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white10,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardGlowPainter extends CustomPainter {
  BoardGlowPainter(this.pulse);

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6B4AFF).withOpacity(0.25 + pulse * 0.2),
          const Color(0x00000000),
        ],
        radius: 0.8,
        center: Alignment.center,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (var i = 0; i < 12; i++) {
      final dy = size.height * (0.15 + i * 0.06);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }
  }

  @override
  bool shouldRepaint(BoardGlowPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

class VaporwaveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF8E4DFF).withOpacity(0.08)
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00FFD1).withOpacity(0.15),
          const Color(0x00000000),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, horizonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlaceholderShaderPainter extends CustomPainter {
  PlaceholderShaderPainter({
    required this.colors,
    required this.pulse,
    required this.params,
  });

  final List<Color> colors;
  final double pulse;
  final VisualizerParams params;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: [
        colors.first.withOpacity(0.3 + params.chaos * 0.4),
        colors.last.withOpacity(0.15 + params.morph * 0.4),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final backgroundPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final swirlPaint = Paint()
      ..color = Colors.white.withOpacity(0.07 + params.speed * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = size.center(Offset.zero);
    for (var i = 0; i < 6; i++) {
      final radius = (size.shortestSide * (0.12 + i * 0.1)) + pulse * 8;
      canvas.drawCircle(center, radius, swirlPaint);
    }

    final glitchPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (var i = 0; i < 10; i++) {
      final y = size.height * (0.1 + i * 0.08);
      final offset = sin((pulse + i) * 3.14) * 12;
      canvas.drawLine(
        Offset(10 + offset, y),
        Offset(size.width - 10 + offset, y),
        glitchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlaceholderShaderPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.params != params;
  }
}

class MarbleShaderPainter extends CustomPainter {
  MarbleShaderPainter({
    required this.seed,
    required this.pulse,
    required this.isEmpty,
  });

  final double seed;
  final double pulse;
  final bool isEmpty;

  @override
  void paint(Canvas canvas, Size size) {
    if (isEmpty) return;
    final center = size.center(Offset.zero);
    final ripplePaint = Paint()
      ..color = Colors.white.withOpacity(0.2 + pulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 3; i++) {
      final radius = size.shortestSide * (0.2 + i * 0.18) +
          sin(seed + pulse * 6.28) * 4;
      canvas.drawCircle(center, radius, ripplePaint);
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final angle = seed + i * pi / 3 + pulse;
      final dx = cos(angle) * size.shortestSide * 0.45;
      final dy = sin(angle) * size.shortestSide * 0.45;
      canvas.drawLine(center, center + Offset(dx, dy), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MarbleShaderPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.seed != seed;
  }
}

class GameState {
  GameState({
    required this.slots,
    required this.currentPlayer,
    required this.holoCount,
    required this.quantumCount,
  });

  final List<BoardSlot> slots;
  PlayerSide currentPlayer;
  int holoCount;
  int quantumCount;

  static GameState initial() {
    final slots = <BoardSlot>[];
    const rowCounts = [5, 6, 7, 8, 9, 8, 7, 6, 5];
    const startX = 24.0;
    const startY = 40.0;
    const spacing = 54.0;
    var seedIndex = 0;

    for (var row = 0; row < rowCounts.length; row++) {
      final count = rowCounts[row];
      final offsetX = (9 - count) * 0.5 * spacing;
      for (var col = 0; col < count; col++) {
        final dx = startX + offsetX + col * spacing;
        final dy = startY + row * spacing * 0.92;
        MarbleState owner;
        if (row < 2) {
          owner = MarbleState.holographic;
        } else if (row > 6) {
          owner = MarbleState.quantum;
        } else {
          owner = MarbleState.empty;
        }
        slots.add(BoardSlot(
          row: row,
          column: col,
          position: Offset(dx, dy),
          owner: owner,
          seed: seedIndex * 0.37,
        ));
        seedIndex++;
      }
    }

    return GameState(
      slots: slots,
      currentPlayer: PlayerSide.holographic,
      holoCount: slots.where((slot) => slot.owner == MarbleState.holographic).length,
      quantumCount: slots.where((slot) => slot.owner == MarbleState.quantum).length,
    );
  }

  void toggleSlot(BoardSlot slot) {
    final index = slots.indexOf(slot);
    if (index == -1) return;

    final current = slots[index];
    MarbleState next;
    if (current.owner == MarbleState.empty) {
      next = currentPlayer == PlayerSide.holographic
          ? MarbleState.holographic
          : MarbleState.quantum;
    } else if (current.owner == MarbleState.holographic) {
      next = MarbleState.quantum;
    } else {
      next = MarbleState.empty;
    }

    slots[index] = current.copyWith(owner: next);
    holoCount =
        slots.where((slot) => slot.owner == MarbleState.holographic).length;
    quantumCount =
        slots.where((slot) => slot.owner == MarbleState.quantum).length;
  }

  void advanceTurn() {
    currentPlayer = currentPlayer == PlayerSide.holographic
        ? PlayerSide.quantum
        : PlayerSide.holographic;
  }

  VisualizerParams visualParamsFor(PlayerSide side) {
    final total = max(holoCount + quantumCount, 1);
    final isHolo = side == PlayerSide.holographic;
    final myCount = isHolo ? holoCount : quantumCount;
    final theirCount = isHolo ? quantumCount : holoCount;
    final deficit = (theirCount - myCount).clamp(0, total);
    final advantage = (myCount - theirCount).clamp(0, total);
    final balance = (myCount / total).clamp(0.0, 1.0);

    final chaos = (deficit / total) * 0.9 + 0.1;
    final speed = 0.6 + (deficit / total) * 0.9;
    final density = 0.4 + (advantage / total) * 0.6;
    final hue = isHolo ? 290.0 - deficit * 8 : 200.0 + deficit * 6;

    return VisualizerParams(
      chaos: chaos,
      speed: speed,
      density: density,
      morph: 0.35 + balance * 0.5,
      hue: hue,
      intensity: 0.8 + advantage / total * 0.2,
      saturation: 0.75 + advantage / total * 0.2,
      geometry: 4 + (deficit % 6),
      rotation: Vib3Rotation(
        xy: 0.4 + balance,
        xz: 0.2 + deficit * 0.04,
        yz: 0.1 + advantage * 0.03,
        xw: 0.3 + deficit * 0.05,
        yw: 0.5 + advantage * 0.05,
        zw: 0.2 + balance * 0.4,
      ),
    );
  }
}

class BoardSlot {
  const BoardSlot({
    required this.row,
    required this.column,
    required this.position,
    required this.owner,
    required this.seed,
  });

  final int row;
  final int column;
  final Offset position;
  final MarbleState owner;
  final double seed;

  BoardSlot copyWith({MarbleState? owner}) {
    return BoardSlot(
      row: row,
      column: column,
      position: position,
      owner: owner ?? this.owner,
      seed: seed,
    );
  }
}

class VisualizerParams {
  const VisualizerParams({
    required this.chaos,
    required this.speed,
    required this.density,
    required this.morph,
    required this.hue,
    required this.intensity,
    required this.saturation,
    required this.geometry,
    required this.rotation,
  });

  final double chaos;
  final double speed;
  final double density;
  final double morph;
  final double hue;
  final double intensity;
  final double saturation;
  final int geometry;
  final Vib3Rotation rotation;

  @override
  bool operator ==(Object other) {
    return other is VisualizerParams &&
        other.chaos == chaos &&
        other.speed == speed &&
        other.density == density &&
        other.morph == morph &&
        other.hue == hue &&
        other.intensity == intensity &&
        other.saturation == saturation &&
        other.geometry == geometry &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(
        chaos,
        speed,
        density,
        morph,
        hue,
        intensity,
        saturation,
        geometry,
        rotation,
      );
}
