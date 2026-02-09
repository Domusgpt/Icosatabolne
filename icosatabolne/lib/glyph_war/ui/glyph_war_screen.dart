import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../game_logic.dart';
import 'glyph_visuals.dart';

class GlyphWarScreen extends StatefulWidget {
  const GlyphWarScreen({super.key});

  @override
  State<GlyphWarScreen> createState() => _GlyphWarScreenState();
}

class _GlyphWarScreenState extends State<GlyphWarScreen> {
  late final GlyphWarController _gameController;
  late final GlyphVisualController _visualController;
  final Map<String, Offset> _pilePositions = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _gameController = GlyphWarController();
    _visualController = GlyphVisualController();
    _initVisuals();
    _gameController.addListener(_onGameUpdate);
  }

  Future<void> _initVisuals() async {
    await _visualController.initialize();
    if (mounted) setState(() {});
  }

  void _onGameUpdate() {
    _visualController.update(_gameController);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gameController.removeListener(_onGameUpdate);
    _gameController.dispose();
    _visualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Layer A: Background (Deep Field)
            Positioned.fill(
              child: SharedVisualizerWidget(
                engine: _visualController.boardEngine,
                fit: BoxFit.cover,
              ),
            ),

            // Layer B: Gameplay
            SafeArea(
              child: Column(
                children: [
                  // Player 2 Area (Opponent)
                  Expanded(
                    flex: 2,
                    child: _PlayerArea(
                      playerId: 'P2',
                      isOpponent: true,
                      visualController: _visualController,
                    ),
                  ),

                  // Pile Area
                  Expanded(
                    flex: 4,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _PileArea(
                          constraints: constraints,
                          pilePositions: _pilePositions,
                          visualController: _visualController,
                        );
                      },
                    ),
                  ),

                  // Player 1 Area (Me)
                  Expanded(
                    flex: 3, // slightly larger for controls
                    child: _PlayerArea(
                      playerId: 'P1',
                      isOpponent: false,
                      visualController: _visualController,
                    ),
                  ),
                ],
              ),
            ),

            // Layer C: Bezel/HUD Overlay
            IgnorePointer(
              child: SharedVisualizerWidget(
                engine: _visualController.bezelEngine,
                fit: BoxFit.fill,
              ),
            ),

            // Game Over Overlay
            if (_gameController.phase == GlyphWarPhase.gameOver)
              const _GameOverOverlay(),
          ],
        ),
      ),
    );
  }
}

class _PileArea extends StatelessWidget {
  final BoxConstraints constraints;
  final Map<String, Offset> pilePositions;
  final GlyphVisualController visualController;

  const _PileArea({
    required this.constraints,
    required this.pilePositions,
    required this.visualController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GlyphWarController>();
    final pile = controller.pile;
    final random = Random(42); // Consistent seed for initial positions logic if needed

    return Stack(
      children: [
        for (final glyph in pile) _buildPileGlyph(glyph, context),
      ],
    );
  }

  Widget _buildPileGlyph(Glyph glyph, BuildContext context) {
    // Determine position
    if (!pilePositions.containsKey(glyph.id)) {
      pilePositions[glyph.id] = Offset(
        (Random().nextDouble() * 0.8 + 0.1) * constraints.maxWidth,
        (Random().nextDouble() * 0.8 + 0.1) * constraints.maxHeight,
      );
    }
    final pos = pilePositions[glyph.id]!;

    return Positioned(
      left: pos.dx - 30, // center it (assuming 60 size)
      top: pos.dy - 30,
      child: Draggable<String>(
        data: glyph.id,
        feedback: _GlyphWidget(
          glyph: glyph,
          visualController: visualController,
          scale: 1.2,
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _GlyphWidget(
            glyph: glyph,
            visualController: visualController,
          ),
        ),
        child: _GlyphWidget(
          glyph: glyph,
          visualController: visualController,
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  final String playerId;
  final bool isOpponent;
  final GlyphVisualController visualController;

  const _PlayerArea({
    required this.playerId,
    required this.isOpponent,
    required this.visualController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GlyphWarController>();
    final playerState = playerId == 'P1' ? controller.player1 : controller.player2;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: isOpponent
            ? Border(bottom: BorderSide(color: Colors.white24))
            : Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        mainAxisAlignment: isOpponent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isOpponent) ...[
            _WordRack(playerState: playerState, visualController: visualController, isOpponent: true),
            const SizedBox(height: 10),
            _StashSlot(playerState: playerState, visualController: visualController, playerId: playerId),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StashSlot(playerState: playerState, visualController: visualController, playerId: playerId),
                if (!isOpponent) _Controls(playerId: playerId),
              ],
            ),
            const SizedBox(height: 10),
            _WordRack(playerState: playerState, visualController: visualController, isOpponent: false),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final String playerId;

  const _Controls({required this.playerId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GlyphWarController>();
    final player = playerId == 'P1' ? controller.player1 : controller.player2;
    final canAttack = controller.phase == GlyphWarPhase.scramble && player.wordLength > 0;

    return Row(
      children: [
        ElevatedButton(
          onPressed: () => controller.dissolveWord(playerId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.5)),
          child: const Text("DISSOLVE"),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: canAttack ? () => controller.startAttack(playerId) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAttack ? Colors.redAccent : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: Text(controller.phase == GlyphWarPhase.attack ? "${controller.attackTimeRemaining}" : "ATTACK"),
        ),
      ],
    );
  }
}

class _StashSlot extends StatelessWidget {
  final PlayerState playerState;
  final GlyphVisualController visualController;
  final String playerId;

  const _StashSlot({
    required this.playerState,
    required this.visualController,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GlyphWarController>();

    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (glyphId) {
        controller.stashGlyph(glyphId, playerId);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => controller.unstashGlyph(playerId),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white10,
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (candidateData.isNotEmpty)
                  BoxShadow(color: Colors.amberAccent, blurRadius: 10),
              ],
            ),
            child: playerState.stashedGlyph != null
                ? Center(
                    child: _GlyphWidget(
                      glyph: playerState.stashedGlyph!,
                      visualController: visualController,
                    ),
                  )
                : const Center(child: Text("STASH", style: TextStyle(color: Colors.white54, fontSize: 10))),
          ),
        );
      },
    );
  }
}

class _WordRack extends StatelessWidget {
  final PlayerState playerState;
  final GlyphVisualController visualController;
  final bool isOpponent;

  const _WordRack({
    required this.playerState,
    required this.visualController,
    required this.isOpponent,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GlyphWarController>();

    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (glyphId) {
        // If dropping on rack, it appends
        controller.grabGlyph(glyphId, isOpponent ? 'P2' : 'P1');
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black45,
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.cyanAccent : Colors.white24,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (candidateData.isNotEmpty)
                const BoxShadow(color: Colors.cyanAccent, blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: playerState.currentWord.map((glyph) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () {
                    if (isOpponent) {
                      // Tether effect
                      controller.tugGlyph(glyph.id, 'P1'); // Assuming I am P1
                    }
                  },
                  child: _GlyphWidget(
                    glyph: glyph,
                    visualController: visualController,
                    isOpponent: isOpponent,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _GlyphWidget extends StatelessWidget {
  final Glyph glyph;
  final GlyphVisualController visualController;
  final bool isOpponent;
  final double scale;

  const _GlyphWidget({
    required this.glyph,
    required this.visualController,
    this.isOpponent = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Parallax calculation needs screen position, tricky inside generic widget.
    // For now, center alignment or random?
    // Or use LayoutBuilder to get offset? No, RenderObject needed.
    // We'll stick to center alignment for efficiency for now, or animated random drift?

    final isTugged = glyph.tuggedByPlayerId != null;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // Dark background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTugged ? Colors.redAccent : Colors.white.withOpacity(0.8),
            width: isTugged ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTugged ? Colors.red : Colors.cyan.withOpacity(0.3),
              blurRadius: isTugged ? 10 : 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // The "Fire" inside
              SharedVisualizerWidget(
                engine: visualController.glyphEngine,
                fit: BoxFit.cover,
                alignment: Alignment(
                  sin(glyph.hashCode), // Pseudo-random fixed alignment per glyph
                  cos(glyph.hashCode),
                ),
              ),
              // The Letter Mask (Negative Space)
              Center(
                child: Text(
                  glyph.char,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Inverted by blend mode?
                    // To make text transparent and background visible:
                    // Use ShaderMask or just white text on top of visualizer?
                    // "The letters... are windows".
                    // If text is white, it blocks the visualizer.
                    // If text is transparent, we see visualizer.
                    // But we want the visualizer INSIDE the text shape.
                    // ShaderMask with the visualizer texture applied to the text!
                  ),
                ),
              ),
              // Better: Full visualizer background, Black overlay with Text cutout?
              // Difficult.
              // Compromise: White text with shadow to make it readable against chaos.
            ],
          ),
        ),
      ).animate(target: isTugged ? 1 : 0).shake(),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GlyphWarController>();
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${controller.winnerId == 'P1' ? 'YOU WIN' : 'OPPONENT WINS'}",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: controller.winnerId == 'P1' ? Colors.cyan : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.resetGame,
              child: const Text("REMATCH"),
            ),
          ],
        ),
      ),
    );
  }
}
