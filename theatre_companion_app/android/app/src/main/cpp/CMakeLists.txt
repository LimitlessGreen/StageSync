cmake_minimum_required(VERSION 3.10)
project(miniaudio_wrapper C)

# Download miniaudio.h if not present.
set(MINIAUDIO_H "${CMAKE_CURRENT_BINARY_DIR}/miniaudio.h")
if(NOT EXISTS "${MINIAUDIO_H}")
  file(DOWNLOAD
    "https://raw.githubusercontent.com/mackron/miniaudio/0.11.21/miniaudio.h"
    "${MINIAUDIO_H}"
    STATUS _dl_status
  )
endif()

add_library(miniaudio_wrapper SHARED
  "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native/miniaudio_wrapper.c"
)

target_include_directories(miniaudio_wrapper PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native"
  "${CMAKE_CURRENT_BINARY_DIR}"
)

target_compile_definitions(miniaudio_wrapper PRIVATE MA_ENABLE_OPENSL)
target_link_libraries(miniaudio_wrapper PRIVATE OpenSLES log)

# AAudio ist erst ab Android API 26 verfügbar.
# Für niedrigere API-Levels bleibt OpenSL ES als Fallback aktiv.
if(CMAKE_SYSTEM_VERSION GREATER_EQUAL 26)
  target_compile_definitions(miniaudio_wrapper PRIVATE MA_ENABLE_AAUDIO)
  target_link_libraries(miniaudio_wrapper PRIVATE aaudio)
endif()
