import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Stream<User?> build() {
    // Ideally: return FirebaseAuth.instance.authStateChanges();
    // But since Firebase isn't initialized yet, we'll return a stream of nulls or mock.
    // We can use a StreamController to simulate auth changes for now if needed.
    // For now, let's just return a stream that emits null (unauthenticated).

    // Once Firebase is initialized in main.dart (even with dummy options),
    // we can try to use the instance.
    // However, without valid config, it might crash or throw.
    // So for safety in this phase, we mock it or handle error.

    try {
        return FirebaseAuth.instance.authStateChanges();
    } catch (e) {
        // Fallback for development without valid firebase config
        return Stream.value(null);
    }
  }

  Future<void> signInAnonymously() async {
      // state = const AsyncLoading(); // Stream provider handles loading automatically via stream?
      // Actually StreamNotifier doesn't have explicit state setter for async loading usually
      // unless we mix in something else or manually emit.
      // But we call methods on FirebaseAuth.

      try {
          await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
          // Log error
          debugPrint('Auth error: $e');
      }
  }

  Future<void> signOut() async {
      await FirebaseAuth.instance.signOut();
  }
}
