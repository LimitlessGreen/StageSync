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

# ── Library target ────────────────────────────────────────────────────────────
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
  target_compile_definitions(miniaudio_wrapper PRIVATE
    MA_ENABLE_WASAPI
    # MA_ENABLE_ASIO  # uncomment + add Steinberg ASIO SDK include path
  )
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
    MA_ENABLE_ALSA
    MA_ENABLE_PULSEAUDIO
  )
  target_link_libraries(miniaudio_wrapper PRIVATE dl pthread m)
endif()

target_compile_options(miniaudio_wrapper PRIVATE
  $<$<AND:$<C_COMPILER_ID:GNU,Clang>,$<NOT:$<PLATFORM_ID:Windows>>>: -O2 -ffast-math>
)
