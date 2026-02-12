import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  // Watch auth state changes to trigger redirects
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final hasError = authState.hasError;
      final isAuthenticated = authState.valueOrNull != null;

      final isLogin = state.uri.toString() == '/login';
      // final isOnboarding = state.uri.toString() == '/onboarding'; // Unused

      if (isLoading || hasError) {
        // While loading or error, maybe stay put or show splash?
        // For simplicity, we don't redirect yet.
        return null;
      }

      if (!isAuthenticated) {
        return isLogin ? null : '/login';
      }

      if (isLogin && isAuthenticated) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
    ],
  );
}
