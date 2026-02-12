import 'package:flutter/material.dart';
import 'color_tokens.dart';

class DermalTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DermalColors.primary,
        brightness: Brightness.light,
        primary: DermalColors.primary,
        onPrimary: DermalColors.onPrimary,
        primaryContainer: DermalColors.primaryContainer,
        onPrimaryContainer: DermalColors.onPrimaryContainer,
        secondary: DermalColors.secondary,
        onSecondary: DermalColors.onSecondary,
        secondaryContainer: DermalColors.secondaryContainer,
        onSecondaryContainer: DermalColors.onSecondaryContainer,
        tertiary: DermalColors.tertiary,
        onTertiary: DermalColors.onTertiary,
        error: DermalColors.error,
        onError: DermalColors.onError,
        surface: DermalColors.surface,
        onSurface: DermalColors.onSurface,
        // Using `fromSeed` might override some specific values, but this is fine for now.
        // We can override if needed.
      ),
      scaffoldBackgroundColor: DermalColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: DermalColors.background,
        foregroundColor: DermalColors.onBackground,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DermalColors.primary,
          foregroundColor: DermalColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DermalColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DermalColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      fontFamily: 'Roboto', // Default, can change later if typography specified.
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DermalColors.primary,
        brightness: Brightness.dark,
      ),
      // Basic dark theme derived from seed for now.
    );
  }
}
