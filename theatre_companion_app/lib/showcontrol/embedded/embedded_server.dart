// Conditional import: use FFI implementation on native platforms,
// stub on web (dart:ffi is unavailable there).
export 'embedded_server_stub.dart'
    if (dart.library.ffi) 'embedded_server_ffi.dart';
