import 'package:flutter/material.dart';

class DermalColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF006D77); // Deep Teal
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF83C5BE); // Soft Teal
  static const Color onPrimaryContainer = Color(0xFF001F22);

  // Secondary Colors
  static const Color secondary = Color(0xFFE29578); // Soft Coral/Skin tone hint
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFDDD2);
  static const Color onSecondaryContainer = Color(0xFF2D1600);

  // Tertiary Colors (Accents)
  static const Color tertiary = Color(0xFF00A896); // Vivid Cyan
  static const Color onTertiary = Color(0xFFFFFFFF);

  // Neutral / Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF1A1C1E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1E);

  // Functional
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
