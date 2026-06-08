# Stub CMakeLists.txt for opus_flutter_windows.
# This plugin uses pluginClass: none (Dart-only FFI, no C++ code).
# Flutter's generated_plugins.cmake requires a real library target.
cmake_minimum_required(VERSION 3.14)
project(opus_flutter_windows_project LANGUAGES CXX)

# Minimal stub source so CMake creates a real library target.
set(STUB_SRC "${CMAKE_CURRENT_BINARY_DIR}/opus_flutter_windows_stub.cc")
file(WRITE ${STUB_SRC} "// opus_flutter_windows: Dart-only plugin, no native code.\n")

add_library(opus_flutter_windows_plugin STATIC ${STUB_SRC})
set_target_properties(opus_flutter_windows_plugin PROPERTIES
  CXX_STANDARD 17
)
target_include_directories(opus_flutter_windows_plugin PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${FLUTTER_MANAGED_DIR}/ephemeral/cpp_client_wrapper/include"
  "${FLUTTER_MANAGED_DIR}/ephemeral"
)
set(opus_flutter_windows_plugin_bundled_libraries "" PARENT_SCOPE)
