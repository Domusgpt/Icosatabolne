import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundHapticsManager {
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();

  SoundHapticsManager() {
    _movePlayer.setPlayerMode(PlayerMode.lowLatency);
    _capturePlayer.setPlayerMode(PlayerMode.lowLatency);
    _winPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> triggerMove(double chaos) async {
    // Audio: Play standard move sound, pitch based on chaos
    try {
      await _movePlayer.setPlaybackRate(0.8 + (chaos * 0.4));
      // In a real scenario, we'd play assets/sounds/move.mp3
      // For now, we assume assets exist or fail silently
      await _movePlayer.play(AssetSource('sounds/move.mp3'));
    } catch (_) {
      // Ignore if asset missing
    }

    // Haptics: Exponential increase
    if (chaos < 0.3) {
      await HapticFeedback.lightImpact();
    } else if (chaos < 0.6) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.heavyImpact();
      if (chaos > 0.8) {
        // Double impact for high chaos
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> triggerCapture(double chaos) async {
    try {
      await _capturePlayer.setPlaybackRate(1.0 + (chaos * 0.5));
      await _capturePlayer.play(AssetSource('sounds/capture.mp3'));
    } catch (_) {}

    // Haptics: Heavy + Vibrations
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate(); // Default vibration

    if (chaos > 0.5) {
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> triggerWin() async {
    try {
      await _winPlayer.play(AssetSource('sounds/win.mp3'));
    } catch (_) {}

    // Pattern
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.vibrate();
  }

  void dispose() {
    _movePlayer.dispose();
    _capturePlayer.dispose();
    _winPlayer.dispose();
  }
}
