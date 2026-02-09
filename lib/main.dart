import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vib3_flutter/vib3_flutter.dart';

import 'game_logic.dart';

void main() {
  runApp(const AbaloneVib3App());
}

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
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.0,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
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
  late GameState _gameState;
  late final AnimationController _pulseController;
  late final Vib3Engine _holoEngine;
  late final Vib3Engine _quantumEngine;
  bool _holoReady = false;
  bool _quantumReady = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
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
      _gameState.handleTap(slot.coordinate);
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
    // Generate slots from board for UI
    final slots = boardState.getSlots();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const VaporwaveBackdrop(),
            // Board Layer (Centered)
            Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  child: SizedBox(
                    width: 600,
                    height: 520,
                    child: BoardPanel(
                      slots: slots,
                      onTap: _onTap,
                      pulse: _pulseController,
                      activePlayer: boardState.currentPlayer,
                      selection: boardState.selection,
                      holoEngine: _holoEngine,
                      quantumEngine: _quantumEngine,
                      holoReady: _holoReady,
                      quantumReady: _quantumReady,
                    ),
                  ),
                ),
              ),
            ),
            // HUD Layer (Top/Bottom Overlay)
            Column(
              children: [
                HeaderHUD(
                  currentPlayer: boardState.currentPlayer,
                  holoScore: boardState.holoCaptured,
                  quantumScore: boardState.quantumCaptured,
                ),
                const Spacer(),
                FooterHUD(
                  activePlayer: boardState.currentPlayer,
                  holoParams: boardState.visualParamsFor(PlayerSide.holographic),
                  quantumParams: boardState.visualParamsFor(PlayerSide.quantum),
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

class BoardPanel extends StatelessWidget {
  const BoardPanel({
    super.key,
    required this.slots,
    required this.onTap,
    required this.pulse,
    required this.activePlayer,
    required this.selection,
    required this.holoEngine,
    required this.quantumEngine,
    required this.holoReady,
    required this.quantumReady,
  });

  final List<BoardSlot> slots;
  final ValueChanged<BoardSlot> onTap;
  final Animation<double> pulse;
  final PlayerSide activePlayer;
  final List<HexCoordinate> selection;
  final Vib3Engine holoEngine;
  final Vib3Engine quantumEngine;
  final bool holoReady;
  final bool quantumReady;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visualizer Layers (Behind the board, clipped to marbles)
        if (holoReady)
          Positioned.fill(
            child: ClipPath(
              clipper: MarbleClipper(slots, MarbleState.holographic),
              child: Vib3View(engine: holoEngine),
            ),
          ),
        if (quantumReady)
          Positioned.fill(
            child: ClipPath(
              clipper: MarbleClipper(slots, MarbleState.quantum),
              child: Vib3View(engine: quantumEngine),
            ),
          ),

        // Grid Lines (Subtle glow behind slots)
        CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: BoardGlowPainter(pulse.value),
        ),

        // Slots (Interactive Lenses)
        ...slots.map((slot) {
          final isSelected = selection.contains(slot.coordinate);
          final isActive = slot.owner ==
                  (activePlayer == PlayerSide.holographic
                      ? MarbleState.holographic
                      : MarbleState.quantum) ||
              isSelected;

          return Positioned(
            left: slot.position.dx,
            top: slot.position.dy,
            child: MarbleLensWidget(
              slot: slot,
              pulse: pulse.value,
              onTap: () => onTap(slot),
              isActive: isActive,
              isSelected: isSelected,
            ),
          );
        }),
      ],
    );
  }
}

class MarbleClipper extends CustomClipper<Path> {
  final List<BoardSlot> slots;
  final MarbleState targetOwner;
  final double radius;

  MarbleClipper(this.slots, this.targetOwner, {this.radius = 26.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    for (final slot in slots) {
      if (slot.owner == targetOwner) {
        // Offset slot position by marble radius to center it (slot.position is top-left of widget)
        final center = slot.position + const Offset(26, 26);
        path.addOval(Rect.fromCircle(center: center, radius: radius));
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant MarbleClipper oldClipper) {
    // Reclip if slots changed (e.g., marbles moved)
    // Checking length or ownership changes
    if (oldClipper.slots.length != slots.length) return true;
    for (int i = 0; i < slots.length; i++) {
      if (oldClipper.slots[i].owner != slots[i].owner) return true;
    }
    return oldClipper.targetOwner != targetOwner;
  }
}

class MarbleLensWidget extends StatelessWidget {
  const MarbleLensWidget({
    super.key,
    required this.slot,
    required this.pulse,
    required this.onTap,
    required this.isActive,
    this.isSelected = false,
  });

  final BoardSlot slot;
  final double pulse;
  final VoidCallback onTap;
  final bool isActive;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // The widget itself is just the rim/lens effect and interaction handler.
    // The "content" is revealed by the Clipper in the parent stack.

    final rimColor = slot.owner == MarbleState.holographic
        ? const Color(0xFFB06DFF)
        : slot.owner == MarbleState.quantum
            ? const Color(0xFF39B6FF)
            : Colors.transparent;

    // Empty slots are just dim indicators
    if (slot.owner == MarbleState.empty) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10, width: 1),
            color: Colors.white.withOpacity(0.02),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Glassy rim
          border: Border.all(
            color: isSelected ? Colors.white : rimColor.withOpacity(0.5),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (isActive || isSelected)
              BoxShadow(
                color: rimColor.withOpacity(0.6),
                blurRadius: 16 + pulse * 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.transparent, Colors.white12], // Subtle lens reflection
              stops: [0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderHUD extends StatelessWidget {
  const HeaderHUD({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PlayerStat(
            label: 'HOLOGRAPHIC',
            value: holoScore,
            active: currentPlayer == PlayerSide.holographic,
            color: const Color(0xFFB06DFF),
          ),
          _TurnIndicator(player: currentPlayer),
          _PlayerStat(
            label: 'QUANTUM',
            value: quantumScore,
            active: currentPlayer == PlayerSide.quantum,
            color: const Color(0xFF39B6FF),
          ),
        ],
      ),
    );
  }
}

class _PlayerStat extends StatelessWidget {
  final String label;
  final int value;
  final bool active;
  final Color color;

  const _PlayerStat({
    required this.label,
    required this.value,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white38,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 24,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  final PlayerSide player;

  const _TurnIndicator({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white10,
      ),
      child: Text(
        player == PlayerSide.holographic ? 'HOLO TURN' : 'QUANTUM TURN',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class FooterHUD extends StatelessWidget {
  final PlayerSide activePlayer;
  final VisualizerParams holoParams;
  final VisualizerParams quantumParams;

  const FooterHUD({
    super.key,
    required this.activePlayer,
    required this.holoParams,
    required this.quantumParams,
  });

  @override
  Widget build(BuildContext context) {
    final params = activePlayer == PlayerSide.holographic ? holoParams : quantumParams;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ParamDisplay(label: 'CHAOS', value: params.chaos),
          _ParamDisplay(label: 'DENSITY', value: params.density),
          _ParamDisplay(label: 'SPEED', value: params.speed),
        ],
      ),
    );
  }
}

class _ParamDisplay extends StatelessWidget {
  final String label;
  final double value;

  const _ParamDisplay({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          height: 4,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
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

class BoardGlowPainter extends CustomPainter {
  BoardGlowPainter(this.pulse);

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid glow behind the board
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6B4AFF).withOpacity(0.1 + pulse * 0.1),
          const Color(0x00000000),
        ],
        radius: 0.6,
        center: Alignment.center,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(BoardGlowPainter oldDelegate) => oldDelegate.pulse != pulse;
}

class VaporwaveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF8E4DFF).withOpacity(0.08)
      ..strokeWidth = 1;

    const spacing = 42.0;
    // Horizon perspective effect
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChromaticAberrationOverlay extends StatelessWidget {
  const ChromaticAberrationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.15,
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionalTranslation(
                translation: const Offset(-0.003, 0),
                child: Container(color: Colors.redAccent.withOpacity(0.1)),
              ),
            ),
            Positioned.fill(
              child: FractionalTranslation(
                translation: const Offset(0.003, 0),
                child: Container(color: Colors.blueAccent.withOpacity(0.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameState {
  final Board board;
  PlayerSide currentPlayer;
  List<HexCoordinate> selection = [];

  int get holoCaptured => board.holoCaptured;
  int get quantumCaptured => board.quantumCaptured;

  GameState({
    required this.board,
    required this.currentPlayer,
  });

  static GameState initial() {
    return GameState(
      board: Board(),
      currentPlayer: PlayerSide.holographic,
    );
  }

  List<BoardSlot> getSlots() {
    final slots = <BoardSlot>[];
    const startX = 24.0;
    const startY = 40.0;
    const spacing = 54.0;
    var seedIndex = 0;

    for (var row = 0; row < 9; row++) {
      int z = row - 4;
      int count = 9 - z.abs();
      int firstX = max(-4, -4 - z);

      final offsetX = (9 - count) * 0.5 * spacing;

      for (var col = 0; col < count; col++) {
        final dx = startX + offsetX + col * spacing;
        final dy = startY + row * spacing * 0.92;

        int x = firstX + col;
        int y = -x - z;
        var coord = HexCoordinate(x, y, z);

        var owner = board.get(coord) ?? MarbleState.empty;

        slots.add(BoardSlot(
          row: row,
          column: col,
          position: Offset(dx, dy),
          owner: owner,
          seed: seedIndex * 0.37,
          coordinate: coord,
        ));
        seedIndex++;
      }
    }
    return slots;
  }

  void handleTap(HexCoordinate coord) {
    var marble = board.get(coord) ?? MarbleState.empty;
    var isCurrentPlayerMarble =
        (currentPlayer == PlayerSide.holographic && marble == MarbleState.holographic) ||
            (currentPlayer == PlayerSide.quantum && marble == MarbleState.quantum);

    if (isCurrentPlayerMarble) {
      if (selection.contains(coord)) {
        selection.remove(coord);
      } else {
        List<HexCoordinate> nextSelection = List.from(selection)..add(coord);
        MoveValidator validator = MoveValidator(board);

        if (validator.validateSelection(nextSelection, currentPlayer)) {
          selection.add(coord);
        } else {
          selection = [coord];
        }
      }
    } else {
      if (selection.isNotEmpty) {
        MoveValidator validator = MoveValidator(board);
        for (var dir in Direction.values) {
          bool targetMatches = false;
          for (var s in selection) {
            if (s.neighbor(dir) == coord) {
              targetMatches = true;
              break;
            }
          }

          if (targetMatches) {
            if (validator.validateMove(selection, dir, currentPlayer)) {
              board.executeMove(selection, dir);
              selection.clear();
              advanceTurn();
              return;
            }
          }
        }
      }
    }
  }

  void advanceTurn() {
    currentPlayer = currentPlayer == PlayerSide.holographic
        ? PlayerSide.quantum
        : PlayerSide.holographic;
  }

  VisualizerParams visualParamsFor(PlayerSide side) {
    final isHolo = side == PlayerSide.holographic;
    final myCaptured = isHolo ? holoCaptured : quantumCaptured;
    final myCount = 14 - myCaptured;
    final theirCaptured = isHolo ? quantumCaptured : holoCaptured;
    final theirCount = 14 - theirCaptured;

    final total = max(myCount + theirCount, 1);
    final deficit = (theirCount - myCount).clamp(0, 14);
    final advantage = (myCount - theirCount).clamp(0, 14);
    final balance = (myCount / total).clamp(0.0, 1.0);

    final chaos = (deficit / 14.0) * 0.9 + 0.1;
    final speed = 0.6 + (deficit / 14.0) * 0.9;
    final density = 0.4 + (advantage / 14.0) * 0.6;
    final hue = isHolo ? 290.0 - deficit * 8 : 200.0 + deficit * 6;

    return VisualizerParams(
      chaos: chaos,
      speed: speed,
      density: density,
      morph: 0.35 + balance * 0.5,
      hue: hue,
      intensity: 0.8 + advantage / 14.0 * 0.2,
      saturation: 0.75 + advantage / 14.0 * 0.2,
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
    required this.coordinate,
  });

  final int row;
  final int column;
  final Offset position;
  final MarbleState owner;
  final double seed;
  final HexCoordinate coordinate;
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
  bool operator ==(Object other) =>
      other is VisualizerParams &&
      other.chaos == chaos &&
      other.speed == speed &&
      other.density == density &&
      other.hue == hue;

  @override
  int get hashCode => Object.hash(chaos, speed, density, hue);
}
