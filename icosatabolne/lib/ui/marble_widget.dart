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

  const MarbleWidget({
    super.key,
    required this.player,
    this.size = 40,
    this.chaosLevel = 0.0,
    this.isSelected = false,
    this.hueShift = 0.0,
    this.speed = 1.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final system = player == Player.holographic ? 'holographic' : 'quantum';
    final geometry = player == Player.holographic ? 0 : 8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: isSelected ? [
          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
        ] : [],
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
          speed: speed,
          hue: 200 + hueShift,
          animate: animate,
        ),
      ),
    );
  }
}
