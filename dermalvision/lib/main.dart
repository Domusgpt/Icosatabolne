import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/theme/dermal_theme.dart';
import 'app/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // In dev, without valid config, this might fail or warn.
    // We catch it so the app still runs (auth will fail though).
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: DermalVisionApp()));
}

class DermalVisionApp extends ConsumerWidget {
  const DermalVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DermalVision',
      theme: DermalTheme.lightTheme,
      darkTheme: DermalTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
