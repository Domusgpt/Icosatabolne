import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/camera_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Basic lifecycle handling:
    // When the app goes to background, the camera might be released by the OS.
    // When returning, we might need to re-initialize.
    // Since our provider manages the controller, invalidating it might be the cleanest way to force re-init.

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free up resources
      // Ideally, we'd tell the provider to dispose the controller.
      // But invalidating the provider will trigger disposal (due to autoDispose/ref.onDispose)
      // and then re-creation when next watched?
      // Actually, if we are still watching it, invalidating it triggers a rebuild immediately.
      // We might want to just let it be for now and rely on navigation disposal.
    } else if (state == AppLifecycleState.resumed) {
      // If we are coming back, we might need to ensure controller is valid.
      ref.invalidate(cameraControllerNotifierProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          cameraState.when(
            data: (controller) {
              if (controller == null || !controller.value.isInitialized) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: CameraPreview(controller),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Camera Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),

          // 2. UI Overlay (Back button, Capture button)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Bar / Capture
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        // Placeholder capture action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Capture clicked (Demo)')),
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
