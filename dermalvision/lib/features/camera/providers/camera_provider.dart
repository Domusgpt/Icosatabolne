import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_provider.g.dart';

@riverpod
class CameraControllerNotifier extends _$CameraControllerNotifier {
  CameraController? _controller;

  @override
  Future<CameraController?> build() async {
    // 1. Request permissions
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Camera permission denied');
    }

    // 2. Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    // 3. Select front camera (usually index 1, or check lens direction)
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // 4. Initialize controller
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high, // Good balance for ML Kit
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Required for Android ML Kit
    );

    await _controller!.initialize();

    // Ensure we dispose properly when provider is destroyed
    ref.onDispose(() {
      _controller?.dispose();
    });

    return _controller;
  }
}
