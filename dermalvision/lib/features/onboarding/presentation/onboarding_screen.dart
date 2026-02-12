import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to DermalVision!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to home logic later
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
