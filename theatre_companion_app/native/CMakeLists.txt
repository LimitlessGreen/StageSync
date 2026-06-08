cmake_minimum_required(VERSION 3.14)
# No project() call here — this is an add_subdirectory() target of the Flutter
# Windows project. Calling project() would generate a separate cmake_install.cmake
# that can't resolve Flutter's generator-expression install prefix.

# ── Locate miniaudio.h ────────────────────────────────────────────────────────
# Search order:
#   1. native/ directory (commit the header alongside the wrapper for offline builds)
#   2. Go module cache (malgo bundles miniaudio.h — already on the developer's machine)
#   3. Download from GitHub as last resort
set(MINIAUDIO_H "")

# 1. Bundled next to this file.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio.h")
  set(MINIAUDIO_H "${CMAKE_CURRENT_SOURCE_DIR}")
  message(STATUS "[miniaudio] using bundled miniaudio.h")
endif()

# 2. Go module cache (Windows path pattern).
if(NOT MINIAUDIO_H)
  set(_MALGO_PATHS
    "$ENV{GOPATH}/pkg/mod/github.com/gen2brain/malgo@v0.11.25"
    "$ENV{USERPROFILE}/go/pkg/mod/github.com/gen2brain/malgo@v0.11.25"
    "$ENV{HOME}/go/pkg/mod/github.com/gen2brain/malgo@v0.11.25"
  )
  foreach(_p ${_MALGO_PATHS})
    if(EXISTS "${_p}/miniaudio.h")
      set(MINIAUDIO_H "${_p}")
      message(STATUS "[miniaudio] found in Go module cache: ${_p}")
      break()
    endif()
  endforeach()
endif()

# 3. Cached download.
if(NOT MINIAUDIO_H)
  set(_DL_DIR "${CMAKE_CURRENT_BINARY_DIR}/miniaudio_dl")
  set(_DL_FILE "${_DL_DIR}/miniaudio.h")
  if(NOT EXISTS "${_DL_FILE}")
    message(STATUS "[miniaudio] Downloading miniaudio.h (0.11.21)...")
    file(MAKE_DIRECTORY "${_DL_DIR}")
    file(DOWNLOAD
      "https://raw.githubusercontent.com/mackron/miniaudio/0.11.21/miniaudio.h"
      "${_DL_FILE}"
      TIMEOUT 30
      STATUS _dl_status
    )
    list(GET _dl_status 0 _dl_code)
    if(NOT _dl_code EQUAL 0)
      message(WARNING
        "[miniaudio] Download failed (${_dl_status}).\n"
        "To fix: copy miniaudio.h to ${CMAKE_CURRENT_SOURCE_DIR}/miniaudio.h\n"
        "Source:  https://github.com/mackron/miniaudio/raw/0.11.21/miniaudio.h\n"
        "Or:      cp \$GOPATH/pkg/mod/github.com/gen2brain/malgo@v0.11.25/miniaudio.h "
        "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio.h"
      )
    endif()
  endif()
  if(EXISTS "${_DL_FILE}")
    set(MINIAUDIO_H "${_DL_DIR}")
    message(STATUS "[miniaudio] using downloaded miniaudio.h")
  endif()
endif()

if(NOT MINIAUDIO_H)
  message(FATAL_ERROR
    "[miniaudio] miniaudio.h not found!\n"
    "Fix: copy miniaudio.h into ${CMAKE_CURRENT_SOURCE_DIR}/\n"
    "     cp \$GOPATH/pkg/mod/github.com/gen2brain/malgo@v0.11.25/miniaudio.h "
    "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio.h"
  )
endif()

# ── ASIO SDK Detection (Windows only) ────────────────────────────────────────
# Download the free Steinberg ASIO SDK from:
#   https://www.steinberg.net/asiosdk
# Then either:
#   a) Set env var ASIO_SDK_DIR to the extracted SDK directory, OR
#   b) Place/symlink it at native/../asio_sdk/ (next to this file's parent)
#
# Without the SDK, WASAPI is used (good latency but not ASIO-exclusive).
set(ASIO_SDK_DIR "")
if(WIN32)
  set(_ASIO_SEARCH_PATHS
    "$ENV{ASIO_SDK_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../asio_sdk"
    "${CMAKE_CURRENT_SOURCE_DIR}/asio_sdk"
    "C:/ASIOSDK2.3.3"
    "C:/ASIOSDK"
    "$ENV{USERPROFILE}/ASIOSDK2.3.3"
    "$ENV{USERPROFILE}/asio_sdk"
  )
  foreach(_p ${_ASIO_SEARCH_PATHS})
    if(EXISTS "${_p}/common/iasiodrv.h")
      set(ASIO_SDK_DIR "${_p}")
      message(STATUS "[miniaudio] ASIO SDK found: ${_p}")
      break()
    endif()
  endforeach()
  if(NOT ASIO_SDK_DIR)
    message(STATUS "[miniaudio] ASIO SDK not found — using WASAPI. "
      "Set ASIO_SDK_DIR env var or place SDK at native/../asio_sdk/ to enable ASIO.")
  endif()
endif()

# ── miniaudio_wrapper library ─────────────────────────────────────────────────
add_library(miniaudio_wrapper SHARED
  "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio_wrapper.c"
)

target_include_directories(miniaudio_wrapper PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${MINIAUDIO_H}"
)

# Define MINIAUDIO_WRAPPER_BUILD so the .c file emits __declspec(dllexport).
target_compile_definitions(miniaudio_wrapper PRIVATE MINIAUDIO_WRAPPER_BUILD)

# ── Platform flags ────────────────────────────────────────────────────────────
if(WIN32)
  target_compile_definitions(miniaudio_wrapper PRIVATE MA_ENABLE_WASAPI)
  if(ASIO_SDK_DIR)
    target_compile_definitions(miniaudio_wrapper PRIVATE MA_ENABLE_ASIO)
    target_include_directories(miniaudio_wrapper PRIVATE
      "${ASIO_SDK_DIR}/common"
      "${ASIO_SDK_DIR}/host"
      "${ASIO_SDK_DIR}/host/pc"
    )
    message(STATUS "[miniaudio] ASIO enabled for miniaudio_wrapper")
  endif()
  target_link_libraries(miniaudio_wrapper PRIVATE ole32 winmm)
  # Suppress MSVC warnings from miniaudio (it's not our code).
  target_compile_options(miniaudio_wrapper PRIVATE /W0)
elseif(APPLE)
  target_compile_definitions(miniaudio_wrapper PRIVATE MA_ENABLE_COREAUDIO)
  target_link_libraries(miniaudio_wrapper PRIVATE
    "-framework CoreFoundation"
    "-framework CoreAudio"
    "-framework AudioToolbox"
  )
elseif(ANDROID)
  target_compile_definitions(miniaudio_wrapper PRIVATE
    MA_ENABLE_AAUDIO
    MA_ENABLE_OPENSL
  )
  target_link_libraries(miniaudio_wrapper PRIVATE aaudio OpenSLES log)
else()
  target_compile_definitions(miniaudio_wrapper PRIVATE
    MA_ENABLE_JACK
    MA_ENABLE_ALSA
    MA_ENABLE_PULSEAUDIO
  )
  target_link_libraries(miniaudio_wrapper PRIVATE dl pthread m jack)
endif()

target_compile_options(miniaudio_wrapper PRIVATE
  $<$<AND:$<C_COMPILER_ID:GNU,Clang>,$<NOT:$<PLATFORM_ID:Windows>>>: -O2 -ffast-math>
)

# ── stagesync_core: Embedded Go gRPC-Server ───────────────────────────────────
# Builds the CGo-free Go core library (cmd/corelib) as a platform shared library.
# The output is copied next to the app executable so Flutter can load it via FFI.
#
# Requirements:
#   - Go toolchain must be in PATH (https://go.dev)
#   - CGO_ENABLED=1 and a C compiler (MSVC via cl.exe on Windows, clang/gcc on others)
#
# To skip the Go build (e.g. for CI without Go installed), set:
#   cmake -DSTAGESYNC_BUILD_CORE=OFF ...
option(STAGESYNC_BUILD_CORE "Build the embedded Go gRPC core library" ON)

if(STAGESYNC_BUILD_CORE)
  # Path to the Go source relative to this CMakeLists.txt
  set(_CORELIB_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../../stagesync-server/cmd/corelib")

  if(WIN32)
    set(_CORELIB_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/stagesync_core.dll")
    set(_CORELIB_HEADER "${CMAKE_CURRENT_BINARY_DIR}/stagesync_core.h")
    set(_GO_OUTPUT_FLAG "-o" "${_CORELIB_OUTPUT}")
  elseif(APPLE)
    set(_CORELIB_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libstagesync_core.dylib")
    set(_CORELIB_HEADER "${CMAKE_CURRENT_BINARY_DIR}/libstagesync_core.h")
    set(_GO_OUTPUT_FLAG "-o" "${_CORELIB_OUTPUT}")
  else()
    set(_CORELIB_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libstagesync_core.so")
    set(_CORELIB_HEADER "${CMAKE_CURRENT_BINARY_DIR}/libstagesync_core.h")
    set(_GO_OUTPUT_FLAG "-o" "${_CORELIB_OUTPUT}")
  endif()

  # Collect Go source files for dependency tracking.
  file(GLOB_RECURSE _CORELIB_GO_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/../../stagesync-server/**/*.go"
  )

  # Build Go corelib into CMAKE_CURRENT_BINARY_DIR first.
  add_custom_command(
    OUTPUT "${_CORELIB_OUTPUT}" "${_CORELIB_HEADER}"
    COMMAND ${CMAKE_COMMAND} -E env
      CGO_ENABLED=1
      go build
        -buildmode=c-shared
        ${_GO_OUTPUT_FLAG}
        .
    WORKING_DIRECTORY "${_CORELIB_SRC}"
    DEPENDS ${_CORELIB_GO_SOURCES}
    COMMENT "[stagesync_core] Building embedded Go gRPC server..."
    VERBATIM
  )

  add_custom_target(stagesync_core_build ALL
    DEPENDS "${_CORELIB_OUTPUT}"
  )

  # Copy the Go DLL next to miniaudio_wrapper.dll using a POST_BUILD command.
  # $<TARGET_FILE_DIR:miniaudio_wrapper> resolves at build time to the correct
  # per-config output folder (runner/Debug, runner/Release, …) without needing
  # INSTALL_BUNDLE_LIB_DIR, which is only set after native/ is processed.
  cmake_path(GET _CORELIB_OUTPUT FILENAME _CORELIB_FILENAME)
  add_dependencies(miniaudio_wrapper stagesync_core_build)
  add_custom_command(TARGET miniaudio_wrapper POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${_CORELIB_OUTPUT}"
      "$<TARGET_FILE_DIR:miniaudio_wrapper>/${_CORELIB_FILENAME}"
    COMMENT "[stagesync_core] Copying ${_CORELIB_FILENAME} to output directory"
    VERBATIM
  )
endif()
