// miniaudio_wrapper.c — thin C layer over miniaudio for Dart FFI.
//
// Compile with:
//   #define MA_IMPLEMENTATION before including miniaudio.h (done below).
//   Platform backends enabled via compiler flags:
//     Windows: MA_ENABLE_WASAPI (default), MA_ENABLE_ASIO (requires ASIO SDK)
//     macOS:   MA_ENABLE_COREAUDIO (default)
//     Linux:   MA_ENABLE_ALSA / MA_ENABLE_PULSEAUDIO (default)
//     Android: MA_ENABLE_AAUDIO / MA_ENABLE_OPENSL (default)
//
/* ASIO note: miniaudio ASIO support requires the Steinberg ASIO SDK headers.
   Download them and add to include path, then compile with MA_ENABLE_ASIO.
   Without the SDK, WASAPI exclusive mode is used (comparable low latency). */

#ifdef _WIN32
  // Prevent Windows.h from pulling in min/max macros that conflict with stdlib.
  #define WIN32_LEAN_AND_MEAN
  #define NOMINMAX
#endif

/* Include own header FIRST so __declspec(dllexport) from MA_WRAP_API applies
   to all function definitions below (MSVC requires the prior declaration). */
#include "miniaudio_wrapper.h"

#define MA_IMPLEMENTATION
#define MA_NO_ENCODING     /* disable encoder (not needed for playback) */
#include "miniaudio.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifdef _WIN32
  #include <windows.h>  /* for GetSystemTimeAsFileTime */
#else
  #include <time.h>
#endif

// ── Platform time helper ──────────────────────────────────────────────────────

static int64_t now_unix_ms(void) {
#if defined(_WIN32)
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    int64_t t = ((int64_t)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
    // Convert from 100ns intervals since 1601 to ms since 1970.
    return (t - 116444736000000000LL) / 10000LL;
#else
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
#endif
}

// ── Handle ────────────────────────────────────────────────────────────────────

#define MAX_HANDLES 64
#define CUE_ID_LEN  128

typedef struct {
    char         cue_id[CUE_ID_LEN];
    ma_sound     sound;
    int          active;      // 1 = in use
    int          initialised; // ma_sound_init called
} Handle;

static Handle   g_handles[MAX_HANDLES];
static ma_mutex g_mutex;

static Handle* find_handle(const char* cue_id) {
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (g_handles[i].active &&
            strncmp(g_handles[i].cue_id, cue_id, CUE_ID_LEN) == 0) {
            return &g_handles[i];
        }
    }
    return NULL;
}

static Handle* alloc_handle(const char* cue_id) {
    // Replace existing handle for the same cue_id.
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (g_handles[i].active &&
            strncmp(g_handles[i].cue_id, cue_id, CUE_ID_LEN) == 0) {
            if (g_handles[i].initialised) {
                ma_sound_uninit(&g_handles[i].sound);
                g_handles[i].initialised = 0;
            }
            return &g_handles[i];
        }
    }
    // Find free slot.
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (!g_handles[i].active) {
            strncpy(g_handles[i].cue_id, cue_id, CUE_ID_LEN - 1);
            g_handles[i].cue_id[CUE_ID_LEN - 1] = '\0';
            g_handles[i].active = 1;
            g_handles[i].initialised = 0;
            return &g_handles[i];
        }
    }
    return NULL; // table full
}

static void free_handle(Handle* h) {
    if (!h) return;
    if (h->initialised) {
        ma_sound_uninit(&h->sound);
        h->initialised = 0;
    }
    h->active = 0;
}

// ── Engine ────────────────────────────────────────────────────────────────────

static ma_engine  g_engine;
static int        g_engine_ready = 0;
static int32_t    g_current_device_index = -1;

// ── Lifecycle ─────────────────────────────────────────────────────────────────

int32_t ma_wrapper_init(int32_t device_index, uint32_t sample_rate, uint32_t channels) {
    if (g_engine_ready) {
        ma_engine_uninit(&g_engine);
        g_engine_ready = 0;
    }

    ma_mutex_init(&g_mutex);
    memset(g_handles, 0, sizeof(g_handles));

    ma_engine_config cfg = ma_engine_config_init();
    cfg.sampleRate = sample_rate > 0 ? sample_rate : 48000;
    cfg.channels   = channels   > 0 ? channels   : 2;

    /* Select device by index if specified.
       We enumerate via a temporary context, copy the device ID, then use it
       in the engine config. The temporary context is released before init. */
    ma_device_id selected_device_id;
    if (device_index >= 0) {
        ma_context tmp_ctx;
        if (ma_context_init(NULL, 0, NULL, &tmp_ctx) == MA_SUCCESS) {
            ma_device_info* pDeviceInfos = NULL;
            ma_uint32 deviceCount = 0;
            if (ma_context_get_devices(&tmp_ctx, &pDeviceInfos, &deviceCount,
                                       NULL, NULL) == MA_SUCCESS) {
                if ((ma_uint32)device_index < deviceCount) {
                    selected_device_id = pDeviceInfos[device_index].id;
                    cfg.pPlaybackDeviceID = &selected_device_id;
                }
            }
            ma_context_uninit(&tmp_ctx);
        }
    }

    ma_result result = ma_engine_init(&cfg, &g_engine);
    if (result != MA_SUCCESS) return (int32_t)result;

    g_engine_ready = 1;
    g_current_device_index = device_index;
    return 0;
}

void ma_wrapper_deinit(void) {
    if (!g_engine_ready) return;

    ma_mutex_lock(&g_mutex);
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (g_handles[i].active) free_handle(&g_handles[i]);
    }
    ma_mutex_unlock(&g_mutex);

    ma_engine_uninit(&g_engine);
    ma_mutex_uninit(&g_mutex);
    g_engine_ready = 0;
}

// ── Device management ─────────────────────────────────────────────────────────

char* ma_wrapper_list_devices(void) {
    ma_context ctx;
    if (ma_context_init(NULL, 0, NULL, &ctx) != MA_SUCCESS) {
        char* empty = (char*)malloc(3);
        strcpy(empty, "[]");
        return empty;
    }

    ma_device_info* pDeviceInfos;
    ma_uint32 deviceCount = 0;
    ma_context_get_devices(&ctx, &pDeviceInfos, &deviceCount, NULL, NULL);

    // Each entry: ~200 bytes worst case for name + JSON overhead.
    size_t buf_size = 2 + (size_t)deviceCount * 256 + 4;
    char* buf = (char*)malloc(buf_size);
    if (!buf) {
        ma_context_uninit(&ctx);
        return NULL;
    }

    // Determine active backend name.
    const char* backend_name = "unknown";
    switch (ctx.backend) {
        case ma_backend_wasapi:     backend_name = "wasapi"; break;
        case ma_backend_dsound:     backend_name = "directsound"; break;
        case ma_backend_winmm:      backend_name = "winmm"; break;
        case ma_backend_coreaudio:  backend_name = "coreaudio"; break;
        case ma_backend_sndio:      backend_name = "sndio"; break;
        case ma_backend_alsa:       backend_name = "alsa"; break;
        case ma_backend_pulseaudio: backend_name = "pulseaudio"; break;
        case ma_backend_jack:       backend_name = "jack"; break;
        case ma_backend_aaudio:     backend_name = "aaudio"; break;
        case ma_backend_opensl:     backend_name = "opensl"; break;
        default: break;
    }

    int pos = 0;
    buf[pos++] = '[';
    for (ma_uint32 i = 0; i < deviceCount; i++) {
        if (i > 0) buf[pos++] = ',';
        // Escape double quotes in device name.
        char escaped[256] = {0};
        int ei = 0;
        const char* n = pDeviceInfos[i].name;
        for (int ni = 0; n[ni] && ei < 250; ni++) {
            if (n[ni] == '"' || n[ni] == '\\') escaped[ei++] = '\\';
            escaped[ei++] = n[ni];
        }
        pos += snprintf(buf + pos, buf_size - (size_t)pos,
            "{\"index\":%u,\"name\":\"%s\",\"backend\":\"%s\"}",
            i, escaped, backend_name);
    }
    buf[pos++] = ']';
    buf[pos]   = '\0';

    ma_context_uninit(&ctx);
    return buf;
}

int32_t ma_wrapper_set_device(int32_t device_index) {
    if (!g_engine_ready) return -1;
    if (device_index == g_current_device_index) return 0;

    // Re-initialise with new device (ma_engine doesn't support hot-swap).
    return ma_wrapper_init(device_index,
        ma_engine_get_sample_rate(&g_engine),
        ma_engine_get_channels(&g_engine));
}

// ── Playback ──────────────────────────────────────────────────────────────────

int32_t ma_wrapper_preload(const char* cue_id, const char* file_path) {
    if (!g_engine_ready || !cue_id || !file_path) return -1;

    ma_mutex_lock(&g_mutex);
    Handle* h = alloc_handle(cue_id);
    if (!h) { ma_mutex_unlock(&g_mutex); return -1; }

    ma_result r = ma_sound_init_from_file(&g_engine, file_path,
        MA_SOUND_FLAG_DECODE | MA_SOUND_FLAG_NO_SPATIALIZATION,
        NULL, NULL, &h->sound);

    if (r == MA_SUCCESS) {
        h->initialised = 1;
    } else {
        h->active = 0;
    }
    ma_mutex_unlock(&g_mutex);
    return (int32_t)r;
}

void ma_wrapper_unload(const char* cue_id) {
    if (!cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h) free_handle(h);
    ma_mutex_unlock(&g_mutex);
}

int32_t ma_wrapper_play(
    const char* cue_id,
    int64_t     start_unix_ms,
    float       volume_db,
    float       fade_in_ms,
    float       fade_out_ms,
    int32_t     loop)
{
    if (!g_engine_ready || !cue_id) return -1;

    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (!h || !h->initialised) { ma_mutex_unlock(&g_mutex); return -1; }

    // Apply volume (linear from dB).
    float linear_vol = (volume_db <= -100.0f) ? 0.0f
                     : powf(10.0f, volume_db / 20.0f);
    ma_sound_set_volume(&h->sound, linear_vol);
    ma_sound_set_looping(&h->sound, loop ? MA_TRUE : MA_FALSE);

    // Fade in.
    if (fade_in_ms > 0.0f) {
        ma_sound_set_fade_in_milliseconds(&h->sound, 0.0f, linear_vol,
            (ma_uint64)fade_in_ms);
    }

    // Timestamp scheduling.
    if (start_unix_ms > 0) {
        int64_t now_ms  = now_unix_ms();
        int64_t delta   = start_unix_ms - now_ms;
        uint32_t sr     = ma_engine_get_sample_rate(&g_engine);

        if (delta > 0) {
            // Future start: schedule in engine PCM frames.
            ma_uint64 engine_time = ma_engine_get_time_in_pcm_frames(&g_engine);
            ma_uint64 delay_frames = (ma_uint64)((double)delta * sr / 1000.0);
            ma_sound_set_start_time_in_pcm_frames(&h->sound,
                engine_time + delay_frames);
        } else if (delta < -50) {
            // Past start (>50ms): seek to correct offset so timeline stays aligned.
            ma_uint64 offset_frames = (ma_uint64)((-delta) * (double)sr / 1000.0);
            ma_sound_seek_to_pcm_frame(&h->sound, offset_frames);
        }
    }

    ma_result r = ma_sound_start(&h->sound);
    ma_mutex_unlock(&g_mutex);
    return (int32_t)r;
}

void ma_wrapper_stop(const char* cue_id, float fade_out_ms) {
    if (!cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) {
        if (fade_out_ms > 0.0f) {
            float cur_vol = ma_sound_get_volume(&h->sound);
            ma_sound_set_fade_in_milliseconds(&h->sound, cur_vol, 0.0f,
                (ma_uint64)fade_out_ms);
            // Schedule stop after fade.
            uint32_t sr = ma_engine_get_sample_rate(&g_engine);
            ma_uint64 engine_time = ma_engine_get_time_in_pcm_frames(&g_engine);
            ma_uint64 fade_frames = (ma_uint64)(fade_out_ms * sr / 1000.0);
            ma_sound_set_stop_time_in_pcm_frames(&h->sound,
                engine_time + fade_frames);
        } else {
            ma_sound_stop(&h->sound);
        }
    }
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_pause(const char* cue_id) {
    if (!cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) ma_sound_stop(&h->sound);
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_resume(const char* cue_id) {
    if (!cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) ma_sound_start(&h->sound);
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_stop_all(void) {
    if (!g_engine_ready) return;
    ma_mutex_lock(&g_mutex);
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (g_handles[i].active && g_handles[i].initialised) {
            ma_sound_stop(&g_handles[i].sound);
        }
    }
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_free_string(char* str) {
    free(str);
}
