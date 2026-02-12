import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

part 'face_mesh_service.g.dart';

@riverpod
FaceMeshService faceMeshService(Ref ref) {
  return FaceMeshService();
}

class FaceMeshService {
  final FaceMeshDetector _detector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);

  Future<List<FaceMesh>> processImage(InputImage inputImage) async {
    try {
      final List<FaceMesh> meshes = await _detector.processImage(inputImage);
      return meshes;
    } catch (e) {
      // Handle or log error
      debugPrint('Face mesh detection error: $e');
      return [];
    }
  }

  void dispose() {
    _detector.close();
  }
}
