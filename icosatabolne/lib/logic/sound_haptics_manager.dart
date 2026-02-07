import 'package:flutter/services.dart';
import 'dart:async';

/// Manages "Bombastic" Haptics and Sound Effects (Placeholder for sound)
/// Aligned with Vaporwave/Neosumorphic aesthetics.
class SoundHapticsManager {
  static final SoundHapticsManager _instance = SoundHapticsManager._internal();
  factory SoundHapticsManager() => _instance;
  SoundHapticsManager._internal();

  /// Triggered when a standard move is executed.
  /// A crisp, mechanical click.
  Future<void> playMoveEffect() async {
    await HapticFeedback.mediumImpact();
    // Simulate mechanical latch
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Triggered when marbles are pushed.
  /// A heavier, grinding sensation.
  Future<void> playPushEffect() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Triggered when a marble is ejected/captured.
  /// "Bombastic" destruction effect.
  Future<void> playCaptureEffect() async {
    // Triple impact for destruction
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate();
  }

  /// Triggered on Invalid Move.
  /// Glitchy short buzz.
  Future<void> playErrorEffect() async {
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.selectionClick();
  }

  /// Triggered on Game Win.
  /// A crescendo of haptics.
  Future<void> playWinEffect() async {
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(Duration(milliseconds: 100 - (i * 10)));
    }
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
  }

  /// Triggered when selecting marbles.
  /// Light, digital feedback.
  Future<void> playSelectionEffect() async {
    await HapticFeedback.selectionClick();
  }
}
