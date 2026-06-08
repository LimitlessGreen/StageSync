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

/* Returns JSON: [{"index":0,"name":"...","backend":"wasapi","isDefault":true}, ...]
   Free the result with ma_wrapper_free_string(). */
MA_WRAP_API char*   ma_wrapper_list_devices(void);

/* Hot-swap to a different output device. device_index = -1 → system default. */
MA_WRAP_API int32_t ma_wrapper_set_device(int32_t device_index);

/* Sets engine-wide output gain. volume_db: 0 = unity, −∞ = mute. */
MA_WRAP_API void    ma_wrapper_set_master_volume(float volume_db);

// ── Playback ──────────────────────────────────────────────────────────────────

MA_WRAP_API int32_t ma_wrapper_preload(const char* cue_id, const char* file_path);
MA_WRAP_API void    ma_wrapper_unload(const char* cue_id);

/* start_unix_ms : 0 = immediate; > 0 = server-timestamp scheduling.
                   Past by > 50 ms → seeks to correct offset (late-join sync).
   start_time_ms : file position to start from (ms). 0 = beginning.
   end_time_ms   : file position to stop at (ms). 0 = play to end of file.
   fade_in_ms    : volume ramp from 0 → volume_db over this duration.
   fade_out_ms   : volume ramp at end_time (only effective when end_time_ms > 0). */
MA_WRAP_API int32_t ma_wrapper_play(
    const char* cue_id,
    int64_t     start_unix_ms,
    float       volume_db,
    float       fade_in_ms,
    float       fade_out_ms,
    int32_t     loop,
    float       start_time_ms,
    float       end_time_ms);

/* Stops cue, optionally with a linear fade-out. */
MA_WRAP_API void ma_wrapper_stop(const char* cue_id, float fade_out_ms);

/* Pauses cue (playhead stays). fade_ms = 0 → instant. */
MA_WRAP_API void ma_wrapper_pause(const char* cue_id, float fade_ms);

/* Resumes paused cue. fade_ms = 0 → instant. */
MA_WRAP_API void ma_wrapper_resume(const char* cue_id, float fade_ms);

/* Fades cue volume to target_db over duration_ms.
   stop_when_done = 1 → stop (with engine stop) after fade completes. */
MA_WRAP_API void ma_wrapper_fade_volume(
    const char* cue_id,
    float       target_db,
    float       duration_ms,
    int32_t     stop_when_done);

MA_WRAP_API void ma_wrapper_stop_all(void);

// ── Analysis ──────────────────────────────────────────────────────────────────

/* Scans file_path for non-silent content.
   threshold_db : peak threshold below which a frame is considered silent (e.g. -60).
   pad_ms       : extra margin added around the detected content (e.g. 50 ms).
   out_start_ms : file position of the first non-silent frame minus pad_ms.
   out_end_ms   : file position of the last  non-silent frame plus  pad_ms.
   Returns 0 on success, negative on error. */
MA_WRAP_API int32_t ma_wrapper_detect_silence(
    const char* file_path,
    float       threshold_db,
    float       pad_ms,
    float*      out_start_ms,
    float*      out_end_ms);

// ── Memory ────────────────────────────────────────────────────────────────────

MA_WRAP_API void ma_wrapper_free_string(char* str);

#ifdef __cplusplus
}
#endif
