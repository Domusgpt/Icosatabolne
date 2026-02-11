/// VIB3+ Dart FFI Bindings
///
/// Provides direct access to the C++ core via FFI for high-performance
/// 4D geometry operations.
library vib3_ffi;

import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkg_ffi;

// ============================================================================
// Native Library Loading
// ============================================================================

/// Load the native VIB3 library based on platform
DynamicLibrary _loadLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libvib3_flutter.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    return DynamicLibrary.process();
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('vib3_flutter.dll');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libvib3_flutter.so');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

/// Global native library instance
final DynamicLibrary _nativeLib = _loadLibrary();

// ============================================================================
// Native Structs
// ============================================================================

/// Native Vec4 structure
final class NativeVec4 extends Struct {
  @Float()
  external double x;

  @Float()
  external double y;

  @Float()
  external double z;

  @Float()
  external double w;
}

/// Native Rotor4D structure (8 components)
final class NativeRotor4D extends Struct {
  @Float()
  external double s;

  @Float()
  external double xy;

  @Float()
  external double xz;

  @Float()
  external double yz;

  @Float()
  external double xw;

  @Float()
  external double yw;

  @Float()
  external double zw;

  @Float()
  external double xyzw;
}

/// Native 4x4 Matrix (column-major, 64 bytes)
final class NativeMat4x4 extends Struct {
  @Array(16)
  external Array<Float> data;
}

// ============================================================================
// Native Function Typedefs
// ============================================================================

// Vec4 operations
typedef _Vec4CreateNative = Pointer<NativeVec4> Function(Float x, Float y, Float z, Float w);
typedef _Vec4Create = Pointer<NativeVec4> Function(double x, double y, double z, double w);

typedef _Vec4DotNative = Float Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b);
typedef _Vec4Dot = double Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b);

typedef _Vec4LengthNative = Float Function(Pointer<NativeVec4> v);
typedef _Vec4Length = double Function(Pointer<NativeVec4> v);

typedef _Vec4NormalizeNative = Void Function(Pointer<NativeVec4> v);
typedef _Vec4Normalize = void Function(Pointer<NativeVec4> v);

typedef _Vec4FreeNative = Void Function(Pointer<NativeVec4> v);
typedef _Vec4Free = void Function(Pointer<NativeVec4> v);

typedef _Vec4BinaryNative = Pointer<NativeVec4> Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b);
typedef _Vec4Binary = Pointer<NativeVec4> Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b);

typedef _Vec4ScaleNative = Pointer<NativeVec4> Function(Pointer<NativeVec4> v, Float s);
typedef _Vec4Scale = Pointer<NativeVec4> Function(Pointer<NativeVec4> v, double s);

typedef _Vec4LerpNative = Pointer<NativeVec4> Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b, Float t);
typedef _Vec4Lerp = Pointer<NativeVec4> Function(Pointer<NativeVec4> a, Pointer<NativeVec4> b, double t);

// Rotor4D operations
typedef _Rotor4DIdentityNative = Pointer<NativeRotor4D> Function();
typedef _Rotor4DIdentity = Pointer<NativeRotor4D> Function();

typedef _Rotor4DFromPlaneAngleNative = Pointer<NativeRotor4D> Function(Int32 plane, Float angle);
typedef _Rotor4DFromPlaneAngle = Pointer<NativeRotor4D> Function(int plane, double angle);

typedef _Rotor4DFromEuler6Native = Pointer<NativeRotor4D> Function(
  Float xy, Float xz, Float yz, Float xw, Float yw, Float zw
);
typedef _Rotor4DFromEuler6 = Pointer<NativeRotor4D> Function(
  double xy, double xz, double yz, double xw, double yw, double zw
);

typedef _Rotor4DMultiplyNative = Pointer<NativeRotor4D> Function(
  Pointer<NativeRotor4D> a, Pointer<NativeRotor4D> b
);
typedef _Rotor4DMultiply = Pointer<NativeRotor4D> Function(
  Pointer<NativeRotor4D> a, Pointer<NativeRotor4D> b
);

typedef _Rotor4DRotateNative = Pointer<NativeVec4> Function(
  Pointer<NativeRotor4D> r, Pointer<NativeVec4> v
);
typedef _Rotor4DRotate = Pointer<NativeVec4> Function(
  Pointer<NativeRotor4D> r, Pointer<NativeVec4> v
);

typedef _Rotor4DSlerpNative = Pointer<NativeRotor4D> Function(
  Pointer<NativeRotor4D> a, Pointer<NativeRotor4D> b, Float t
);
typedef _Rotor4DSlerp = Pointer<NativeRotor4D> Function(
  Pointer<NativeRotor4D> a, Pointer<NativeRotor4D> b, double t
);

typedef _Rotor4DFreeNative = Void Function(Pointer<NativeRotor4D> r);
typedef _Rotor4DFree = void Function(Pointer<NativeRotor4D> r);

typedef _Rotor4DNormalizeNative = Void Function(Pointer<NativeRotor4D> r);
typedef _Rotor4DNormalize = void Function(Pointer<NativeRotor4D> r);

typedef _Rotor4DToMatrixNative = Pointer<NativeMat4x4> Function(Pointer<NativeRotor4D> r);
typedef _Rotor4DToMatrix = Pointer<NativeMat4x4> Function(Pointer<NativeRotor4D> r);

// Mat4x4 operations
typedef _Mat4x4IdentityNative = Pointer<NativeMat4x4> Function();
typedef _Mat4x4Identity = Pointer<NativeMat4x4> Function();

typedef _Mat4x4RotationSingleNative = Pointer<NativeMat4x4> Function(Float angle);
typedef _Mat4x4RotationSingle = Pointer<NativeMat4x4> Function(double angle);

typedef _Mat4x4RotationFromAnglesNative = Pointer<NativeMat4x4> Function(
  Float xy, Float xz, Float yz, Float xw, Float yw, Float zw
);
typedef _Mat4x4RotationFromAngles = Pointer<NativeMat4x4> Function(
  double xy, double xz, double yz, double xw, double yw, double zw
);

typedef _Mat4x4MultiplyNative = Pointer<NativeMat4x4> Function(
  Pointer<NativeMat4x4> a, Pointer<NativeMat4x4> b
);
typedef _Mat4x4Multiply = Pointer<NativeMat4x4> Function(
  Pointer<NativeMat4x4> a, Pointer<NativeMat4x4> b
);

typedef _Mat4x4MultiplyVec4Native = Pointer<NativeVec4> Function(
  Pointer<NativeMat4x4> m, Pointer<NativeVec4> v
);
typedef _Mat4x4MultiplyVec4 = Pointer<NativeVec4> Function(
  Pointer<NativeMat4x4> m, Pointer<NativeVec4> v
);

typedef _Mat4x4FreeNative = Void Function(Pointer<NativeMat4x4> m);
typedef _Mat4x4Free = void Function(Pointer<NativeMat4x4> m);

// Projection operations
typedef _ProjectPerspectiveNative = Pointer<NativeVec4> Function(
  Pointer<NativeVec4> v, Float distance
);
typedef _ProjectPerspective = Pointer<NativeVec4> Function(
  Pointer<NativeVec4> v, double distance
);

typedef _ProjectStereographicNative = Pointer<NativeVec4> Function(Pointer<NativeVec4> v);
typedef _ProjectStereographic = Pointer<NativeVec4> Function(Pointer<NativeVec4> v);

typedef _ProjectOrthographicNative = Pointer<NativeVec4> Function(Pointer<NativeVec4> v);
typedef _ProjectOrthographic = Pointer<NativeVec4> Function(Pointer<NativeVec4> v);

// Batch operations
typedef _ProcessCommandBatchNative = Int32 Function(
  Pointer<Uint8> commands, Uint32 size, Pointer<Uint8> results
);
typedef _ProcessCommandBatch = int Function(
  Pointer<Uint8> commands, int size, Pointer<Uint8> results
);

// Utility
typedef _VersionNative = Pointer<pkg_ffi.Utf8> Function();
typedef _Version = Pointer<pkg_ffi.Utf8> Function();

typedef _GeometryNameNative = Pointer<pkg_ffi.Utf8> Function(Int32 index);
typedef _GeometryName = Pointer<pkg_ffi.Utf8> Function(int index);

typedef _HasSimdNative = Bool Function();
typedef _HasSimd = bool Function();

// ============================================================================
// Native Function Bindings
// ============================================================================

// Vec4
final _vec4Create = _nativeLib.lookupFunction<_Vec4CreateNative, _Vec4Create>('vib3_vec4_create');
final _vec4Dot = _nativeLib.lookupFunction<_Vec4DotNative, _Vec4Dot>('vib3_vec4_dot');
final _vec4Length = _nativeLib.lookupFunction<_Vec4LengthNative, _Vec4Length>('vib3_vec4_length');
final _vec4Normalize = _nativeLib.lookupFunction<_Vec4NormalizeNative, _Vec4Normalize>('vib3_vec4_normalize');
final _vec4Free = _nativeLib.lookupFunction<_Vec4FreeNative, _Vec4Free>('vib3_vec4_free');
final _vec4Add = _nativeLib.lookupFunction<_Vec4BinaryNative, _Vec4Binary>('vib3_vec4_add');
final _vec4Sub = _nativeLib.lookupFunction<_Vec4BinaryNative, _Vec4Binary>('vib3_vec4_sub');
final _vec4Scale = _nativeLib.lookupFunction<_Vec4ScaleNative, _Vec4Scale>('vib3_vec4_scale');
final _vec4Lerp = _nativeLib.lookupFunction<_Vec4LerpNative, _Vec4Lerp>('vib3_vec4_lerp');

// Rotor4D
final _rotor4DIdentity = _nativeLib.lookupFunction<_Rotor4DIdentityNative, _Rotor4DIdentity>('vib3_rotor4d_identity');
final _rotor4DFromPlaneAngle = _nativeLib.lookupFunction<_Rotor4DFromPlaneAngleNative, _Rotor4DFromPlaneAngle>('vib3_rotor4d_from_plane_angle');
final _rotor4DFromEuler6 = _nativeLib.lookupFunction<_Rotor4DFromEuler6Native, _Rotor4DFromEuler6>('vib3_rotor4d_from_euler6');
final _rotor4DMultiply = _nativeLib.lookupFunction<_Rotor4DMultiplyNative, _Rotor4DMultiply>('vib3_rotor4d_multiply');
final _rotor4DRotate = _nativeLib.lookupFunction<_Rotor4DRotateNative, _Rotor4DRotate>('vib3_rotor4d_rotate');
final _rotor4DSlerp = _nativeLib.lookupFunction<_Rotor4DSlerpNative, _Rotor4DSlerp>('vib3_rotor4d_slerp');
final _rotor4DFree = _nativeLib.lookupFunction<_Rotor4DFreeNative, _Rotor4DFree>('vib3_rotor4d_free');
final _rotor4DNormalize = _nativeLib.lookupFunction<_Rotor4DNormalizeNative, _Rotor4DNormalize>('vib3_rotor4d_normalize');
final _rotor4DToMatrix = _nativeLib.lookupFunction<_Rotor4DToMatrixNative, _Rotor4DToMatrix>('vib3_rotor4d_to_matrix');

// Mat4x4
final _mat4x4Identity = _nativeLib.lookupFunction<_Mat4x4IdentityNative, _Mat4x4Identity>('vib3_mat4x4_identity');
final _mat4x4RotationXY = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_xy');
final _mat4x4RotationXZ = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_xz');
final _mat4x4RotationYZ = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_yz');
final _mat4x4RotationXW = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_xw');
final _mat4x4RotationYW = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_yw');
final _mat4x4RotationZW = _nativeLib.lookupFunction<_Mat4x4RotationSingleNative, _Mat4x4RotationSingle>('vib3_mat4x4_rotation_zw');
final _mat4x4RotationFromAngles = _nativeLib.lookupFunction<_Mat4x4RotationFromAnglesNative, _Mat4x4RotationFromAngles>('vib3_mat4x4_rotation_from_angles');
final _mat4x4Multiply = _nativeLib.lookupFunction<_Mat4x4MultiplyNative, _Mat4x4Multiply>('vib3_mat4x4_multiply');
final _mat4x4MultiplyVec4 = _nativeLib.lookupFunction<_Mat4x4MultiplyVec4Native, _Mat4x4MultiplyVec4>('vib3_mat4x4_multiply_vec4');
final _mat4x4Free = _nativeLib.lookupFunction<_Mat4x4FreeNative, _Mat4x4Free>('vib3_mat4x4_free');

// Projection
final _projectPerspective = _nativeLib.lookupFunction<_ProjectPerspectiveNative, _ProjectPerspective>('vib3_project_perspective');
final _projectStereographic = _nativeLib.lookupFunction<_ProjectStereographicNative, _ProjectStereographic>('vib3_project_stereographic');
final _projectOrthographic = _nativeLib.lookupFunction<_ProjectOrthographicNative, _ProjectOrthographic>('vib3_project_orthographic');

// Batch
final _processCommandBatch = _nativeLib.lookupFunction<_ProcessCommandBatchNative, _ProcessCommandBatch>('vib3_process_command_batch');

// Utility
final _version = _nativeLib.lookupFunction<_VersionNative, _Version>('vib3_version');
final _geometryName = _nativeLib.lookupFunction<_GeometryNameNative, _GeometryName>('vib3_geometry_name');
final _hasSimd = _nativeLib.lookupFunction<_HasSimdNative, _HasSimd>('vib3_has_simd');

// ============================================================================
// Dart Wrapper Classes
// ============================================================================

/// Rotation plane enumeration
enum RotationPlane {
  xy(0),
  xz(1),
  yz(2),
  xw(3),
  yw(4),
  zw(5);

  final int value;
  const RotationPlane(this.value);
}

/// 4D Vector class
class Vec4 {
  Pointer<NativeVec4> _ptr;
  bool _disposed = false;

  Vec4(double x, double y, double z, double w) : _ptr = _vec4Create(x, y, z, w);

  Vec4._fromPointer(this._ptr);

  double get x => _ptr.ref.x;
  double get y => _ptr.ref.y;
  double get z => _ptr.ref.z;
  double get w => _ptr.ref.w;

  set x(double value) => _ptr.ref.x = value;
  set y(double value) => _ptr.ref.y = value;
  set z(double value) => _ptr.ref.z = value;
  set w(double value) => _ptr.ref.w = value;

  double dot(Vec4 other) {
    _checkDisposed();
    return _vec4Dot(_ptr, other._ptr);
  }

  double get length {
    _checkDisposed();
    return _vec4Length(_ptr);
  }

  void normalize() {
    _checkDisposed();
    _vec4Normalize(_ptr);
  }

  Vec4 normalized() {
    _checkDisposed();
    final result = Vec4(x, y, z, w);
    result.normalize();
    return result;
  }

  Vec4 operator +(Vec4 other) {
    _checkDisposed();
    return Vec4._fromPointer(_vec4Add(_ptr, other._ptr));
  }

  Vec4 operator -(Vec4 other) {
    _checkDisposed();
    return Vec4._fromPointer(_vec4Sub(_ptr, other._ptr));
  }

  Vec4 operator *(double scalar) {
    _checkDisposed();
    return Vec4._fromPointer(_vec4Scale(_ptr, scalar));
  }

  Vec4 lerp(Vec4 other, double t) {
    _checkDisposed();
    return Vec4._fromPointer(_vec4Lerp(_ptr, other._ptr, t));
  }

  Float32List toFloat32List() => Float32List.fromList([x, y, z, w]);

  void _checkDisposed() {
    if (_disposed) throw StateError('Vec4 has been disposed');
  }

  void dispose() {
    if (!_disposed) {
      _vec4Free(_ptr);
      _disposed = true;
    }
  }

  @override
  String toString() => 'Vec4($x, $y, $z, $w)';
}

/// 4D Rotor class (8 components for proper 4D rotation)
class Rotor4D {
  Pointer<NativeRotor4D> _ptr;
  bool _disposed = false;

  Rotor4D._fromPointer(this._ptr);

  /// Create identity rotor (no rotation)
  factory Rotor4D.identity() {
    return Rotor4D._fromPointer(_rotor4DIdentity());
  }

  /// Create rotor for single-plane rotation
  factory Rotor4D.fromPlaneAngle(RotationPlane plane, double angle) {
    return Rotor4D._fromPointer(_rotor4DFromPlaneAngle(plane.value, angle));
  }

  /// Create rotor from 6 Euler angles
  factory Rotor4D.fromEuler6({
    double xy = 0,
    double xz = 0,
    double yz = 0,
    double xw = 0,
    double yw = 0,
    double zw = 0,
  }) {
    return Rotor4D._fromPointer(_rotor4DFromEuler6(xy, xz, yz, xw, yw, zw));
  }

  double get s => _ptr.ref.s;
  double get xy => _ptr.ref.xy;
  double get xz => _ptr.ref.xz;
  double get yz => _ptr.ref.yz;
  double get xw => _ptr.ref.xw;
  double get yw => _ptr.ref.yw;
  double get zw => _ptr.ref.zw;
  double get xyzw => _ptr.ref.xyzw;

  /// Multiply rotors (compose rotations)
  Rotor4D multiply(Rotor4D other) {
    _checkDisposed();
    return Rotor4D._fromPointer(_rotor4DMultiply(_ptr, other._ptr));
  }

  /// Rotate a vector
  Vec4 rotate(Vec4 v) {
    _checkDisposed();
    return Vec4._fromPointer(_rotor4DRotate(_ptr, v._ptr));
  }

  /// Spherical linear interpolation
  Rotor4D slerp(Rotor4D other, double t) {
    _checkDisposed();
    return Rotor4D._fromPointer(_rotor4DSlerp(_ptr, other._ptr, t));
  }

  /// Normalize this rotor
  void normalize() {
    _checkDisposed();
    _rotor4DNormalize(_ptr);
  }

  /// Convert to 4x4 rotation matrix
  Mat4x4 toMatrix() {
    _checkDisposed();
    return Mat4x4._fromPointer(_rotor4DToMatrix(_ptr));
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('Rotor4D has been disposed');
  }

  void dispose() {
    if (!_disposed) {
      _rotor4DFree(_ptr);
      _disposed = true;
    }
  }

  @override
  String toString() => 'Rotor4D(s: $s, xy: $xy, xz: $xz, yz: $yz, xw: $xw, yw: $yw, zw: $zw, xyzw: $xyzw)';
}

/// 4x4 Matrix class (column-major)
class Mat4x4 {
  Pointer<NativeMat4x4> _ptr;
  bool _disposed = false;

  Mat4x4._fromPointer(this._ptr);

  /// Create identity matrix
  factory Mat4x4.identity() {
    return Mat4x4._fromPointer(_mat4x4Identity());
  }

  /// Create rotation matrix for a single plane
  factory Mat4x4.rotationXY(double angle) => Mat4x4._fromPointer(_mat4x4RotationXY(angle));
  factory Mat4x4.rotationXZ(double angle) => Mat4x4._fromPointer(_mat4x4RotationXZ(angle));
  factory Mat4x4.rotationYZ(double angle) => Mat4x4._fromPointer(_mat4x4RotationYZ(angle));
  factory Mat4x4.rotationXW(double angle) => Mat4x4._fromPointer(_mat4x4RotationXW(angle));
  factory Mat4x4.rotationYW(double angle) => Mat4x4._fromPointer(_mat4x4RotationYW(angle));
  factory Mat4x4.rotationZW(double angle) => Mat4x4._fromPointer(_mat4x4RotationZW(angle));

  /// Create rotation matrix from 6 angles
  factory Mat4x4.rotationFromAngles({
    double xy = 0,
    double xz = 0,
    double yz = 0,
    double xw = 0,
    double yw = 0,
    double zw = 0,
  }) {
    return Mat4x4._fromPointer(_mat4x4RotationFromAngles(xy, xz, yz, xw, yw, zw));
  }

  /// Multiply matrices
  Mat4x4 multiply(Mat4x4 other) {
    _checkDisposed();
    return Mat4x4._fromPointer(_mat4x4Multiply(_ptr, other._ptr));
  }

  /// Transform a vector
  Vec4 multiplyVec4(Vec4 v) {
    _checkDisposed();
    return Vec4._fromPointer(_mat4x4MultiplyVec4(_ptr, v._ptr));
  }

  /// Get matrix data as Float32List (column-major)
  Float32List toFloat32List() {
    _checkDisposed();
    final list = Float32List(16);
    for (int i = 0; i < 16; i++) {
      list[i] = _ptr.ref.data[i];
    }
    return list;
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('Mat4x4 has been disposed');
  }

  void dispose() {
    if (!_disposed) {
      _mat4x4Free(_ptr);
      _disposed = true;
    }
  }
}

/// Projection utilities
class Projection {
  /// Perspective projection (4D -> 3D)
  static Vec4 perspective(Vec4 v, double distance) {
    return Vec4._fromPointer(_projectPerspective(v._ptr, distance));
  }

  /// Stereographic projection (4D -> 3D)
  static Vec4 stereographic(Vec4 v) {
    return Vec4._fromPointer(_projectStereographic(v._ptr));
  }

  /// Orthographic projection (4D -> 3D)
  static Vec4 orthographic(Vec4 v) {
    return Vec4._fromPointer(_projectOrthographic(v._ptr));
  }
}

/// VIB3 utility functions
class Vib3Utils {
  /// Get the native library version
  static String get version => _version().cast<pkg_ffi.Utf8>().toDartString();

  /// Get geometry name by index (0-23)
  static String geometryName(int index) => _geometryName(index).cast<pkg_ffi.Utf8>().toDartString();

  /// Whether SIMD is available on this platform
  static bool get hasSimd => _hasSimd();
}

// ============================================================================
// Command Batching
// ============================================================================

/// Command types for batch processing
enum CommandType {
  setParameter(0x01),
  setGeometry(0x02),
  rotate(0x03),
  resetRotation(0x04),
  render(0x05),
  generateGeometry(0x06),
  applyWarp(0x07);

  final int value;
  const CommandType(this.value);
}

/// Command batch builder for minimizing FFI overhead
class CommandBatch {
  final BytesBuilder _builder = BytesBuilder();
  int _commandCount = 0;

  void setParameter(int paramId, double value) {
    _builder.addByte(CommandType.setParameter.value);
    _builder.add(_encodeUint32(paramId));
    _builder.add(_encodeFloat64(value));
    _commandCount++;
  }

  void setGeometry(int geometryIndex) {
    _builder.addByte(CommandType.setGeometry.value);
    _builder.add(_encodeUint32(geometryIndex));
    _commandCount++;
  }

  void rotate(RotationPlane plane, double angle) {
    _builder.addByte(CommandType.rotate.value);
    _builder.addByte(plane.value);
    _builder.add(_encodeFloat64(angle));
    _commandCount++;
  }

  void resetRotation() {
    _builder.addByte(CommandType.resetRotation.value);
    _commandCount++;
  }

  void render() {
    _builder.addByte(CommandType.render.value);
    _commandCount++;
  }

  int get commandCount => _commandCount;

  Uint8List execute() {
    final commands = _builder.toBytes();
    final resultsPtr = calloc<Uint8>(commands.length * 2);
    final commandsPtr = calloc<Uint8>(commands.length);

    for (int i = 0; i < commands.length; i++) {
      commandsPtr[i] = commands[i];
    }

    final resultSize = _processCommandBatch(commandsPtr, commands.length, resultsPtr);

    final results = Uint8List(resultSize);
    for (int i = 0; i < resultSize; i++) {
      results[i] = resultsPtr[i];
    }

    calloc.free(commandsPtr);
    calloc.free(resultsPtr);

    return results;
  }

  void clear() {
    _builder.clear();
    _commandCount = 0;
  }

  Uint8List _encodeUint32(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _encodeFloat64(double value) {
    final data = ByteData(8);
    data.setFloat64(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
}

/// Memory allocator for native memory
final Allocator calloc = pkg_ffi.calloc;
