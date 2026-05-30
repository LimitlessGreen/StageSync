#pragma once
#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* DLL export/import macro — ensures all symbols are visible to dart:ffi.
   The .c file compiles with MINIAUDIO_WRAPPER_BUILD defined → dllexport.
   Dart FFI loads the DLL at runtime → dllimport (or nothing on other platforms). */
#ifdef _WIN32
  #ifdef MINIAUDIO_WRAPPER_BUILD
    #define MA_WRAP_API __declspec(dllexport)
  #else
    #define MA_WRAP_API __declspec(dllimport)
  #endif
#else
  #define MA_WRAP_API __attribute__((visibility("default")))
#endif

// ── Lifecycle ─────────────────────────────────────────────────────────────────

MA_WRAP_API int32_t ma_wrapper_init(int32_t device_index, uint32_t sample_rate, uint32_t channels);
MA_WRAP_API void    ma_wrapper_deinit(void);

// ── Device management ─────────────────────────────────────────────────────────

/* Returns JSON: [{"index":0,"name":"...","backend":"wasapi"}, ...]
   Free the result with ma_wrapper_free_string(). */
MA_WRAP_API char*   ma_wrapper_list_devices(void);

/* Hot-swap to a different output device. device_index = -1 → system default. */
MA_WRAP_API int32_t ma_wrapper_set_device(int32_t device_index);

// ── Playback ──────────────────────────────────────────────────────────────────

MA_WRAP_API int32_t ma_wrapper_preload(const char* cue_id, const char* file_path);
MA_WRAP_API void    ma_wrapper_unload(const char* cue_id);

/* start_unix_ms = 0 → immediate. > 0 → server-timestamp scheduling.
   If in the past by > 50ms, seeks to correct offset (late-join sync). */
MA_WRAP_API int32_t ma_wrapper_play(
    const char* cue_id,
    int64_t     start_unix_ms,
    float       volume_db,
    float       fade_in_ms,
    float       fade_out_ms,
    int32_t     loop);

MA_WRAP_API void ma_wrapper_stop(const char* cue_id, float fade_out_ms);
MA_WRAP_API void ma_wrapper_pause(const char* cue_id);
MA_WRAP_API void ma_wrapper_resume(const char* cue_id);
MA_WRAP_API void ma_wrapper_stop_all(void);

// ── Memory ────────────────────────────────────────────────────────────────────

MA_WRAP_API void ma_wrapper_free_string(char* str);

#ifdef __cplusplus
}
#endif
