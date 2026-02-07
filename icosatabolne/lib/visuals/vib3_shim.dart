// Conditional export
export 'shim/vib3_stub.dart'
  if (dart.library.io) 'shim/vib3_native.dart';
