import 'package:flutter/material.dart';
import 'package:icosatabolne/game/board_state.dart';
import 'package:icosatabolne/visuals/vib3_adapter.dart';
import 'package:icosatabolne/visuals/game_config.dart';

class MarbleWidget extends StatelessWidget {
  final Player player;
  final double size;
  final double chaosLevel; // 0.0 to 1.0
  final bool isSelected;
  final double hueShift;
  final double speed;
  final bool animate;
  final double impact; // Transient visual effect strength (0.0 - 1.0)

  const MarbleWidget({
    super.key,
    required this.player,
    this.size = 40,
    this.chaosLevel = 0.0,
    this.isSelected = false,
    this.hueShift = 0.0,
    this.speed = 1.0,
    this.animate = true,
    this.impact = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final system = player == Player.holographic ? 'holographic' : 'quantum';
    final geometry = player == Player.holographic ? 0 : 8;

    // Dynamic params derived from impact
    final double activeSpeed = speed * (1.0 + impact * 2.0); // Triple speed on impact
    final double activeIntensity = 0.9 + (impact * 1.5); // Burst brightness
    final double activeDistortion = chaosLevel + (impact * 0.5);

    // Geometry Morph on Impact
    // If impact > 0.5, morph geometry slightly to show "stress"
    final double morph = impact > 0.5 ? 0.5 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          if (isSelected)
            BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
          if (impact > 0.1)
            BoxShadow(
              color: (player == Player.holographic ? Colors.cyanAccent : Colors.purpleAccent).withOpacity(impact * 0.8),
              blurRadius: 15 * impact,
              spreadRadius: 5 * impact,
            ),
        ],
      ),
      child: ClipOval(
        child: Vib3Adapter(
          config: GameVib3Config(
            system: system,
            geometry: geometry,
            gridDensity: (32 * (1.0 - chaosLevel * 0.5)).toInt().clamp(4, 32),
          ),
          width: size,
          height: size,
          chaos: chaosLevel,
          speed: activeSpeed,
          hue: 200 + hueShift + (impact * 60.0), // Shift hue on impact
          intensity: activeIntensity,
          geometryMorph: morph,
          distortion: activeDistortion,
          rotXY: impact * 3.14, // Spin on impact
          animate: animate,
        ),
      ),
    );
  }
}
