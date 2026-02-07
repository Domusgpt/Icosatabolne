import 'package:flutter/material.dart';
import 'package:icosatabolne/glyph_war/ui/glyph_war_screen.dart';

void main() {
  runApp(const IcosatabolneApp());
}

class IcosatabolneApp extends StatelessWidget {
  const IcosatabolneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icosatabolne: Glyph War',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      home: const GlyphWarScreen(),
    );
  }
}
