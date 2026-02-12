import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen Placeholder'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simulate login - logic will be handled by provider later
                // For now, just a button
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
