import 'package:flutter/material.dart';
import 'package:icosatabolne/ui/game_screen.dart';

void main() {
  runApp(const IcosatabolneApp());
}

class IcosatabolneApp extends StatelessWidget {
  const IcosatabolneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icosatabolne',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
