// opus_flutter_windows: Dart-only FFI plugin, no C++ registration needed.
// Flutter's generated_plugin_registrant.cc calls noneRegisterWithRegistrar()
// which we provide as a no-op so the build succeeds.
#ifndef FLUTTER_PLUGIN_OPUS_FLUTTER_WINDOWS_NONE_H_
#define FLUTTER_PLUGIN_OPUS_FLUTTER_WINDOWS_NONE_H_

#include <flutter/plugin_registrar_windows.h>

// No-op registration function — all work is done by the Dart FFI layer.
static inline void noneRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  (void)registrar;
}

#endif  // FLUTTER_PLUGIN_OPUS_FLUTTER_WINDOWS_NONE_H_
