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
#include <stdio.h>
#include <ctype.h>
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
static int      g_mutex_ready = 0;

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
static ma_context g_context;
static int        g_engine_ready = 0;
static int        g_context_ready = 0;
static int32_t    g_current_device_index = -1;
static ma_backend g_current_backend = ma_backend_null;

#define MAX_DEVICE_CATALOG 256
typedef struct {
    int32_t    index;
    ma_backend backend;
    ma_device_id device_id;
    char       name[256];
    int        is_default;
} DeviceEntry;

static DeviceEntry g_devices[MAX_DEVICE_CATALOG];
static int32_t     g_device_count = 0;

static const char* backend_to_name(ma_backend backend) {
    switch (backend) {
        case ma_backend_wasapi:     return "wasapi";
        case ma_backend_dsound:     return "directsound";
        case ma_backend_winmm:      return "winmm";
        case ma_backend_coreaudio:  return "coreaudio";
        case ma_backend_sndio:      return "sndio";
        case ma_backend_alsa:       return "alsa";
        case ma_backend_pulseaudio: return "pulseaudio";
        case ma_backend_jack:       return "jack";
        case ma_backend_aaudio:     return "aaudio";
        case ma_backend_opensl:     return "opensl";
        case ma_backend_null:       return "default";
        default:                    return "unknown";
    }
}

static ma_backend backend_from_name(const char* name) {
    if (!name) return ma_backend_null;
    if (strcmp(name, "jack") == 0 || strcmp(name, "jack2") == 0) return ma_backend_jack;
    if (strcmp(name, "pulseaudio") == 0 || strcmp(name, "pulse") == 0) return ma_backend_pulseaudio;
    if (strcmp(name, "alsa") == 0) return ma_backend_alsa;
    if (strcmp(name, "coreaudio") == 0) return ma_backend_coreaudio;
    if (strcmp(name, "wasapi") == 0) return ma_backend_wasapi;
    // Vendored miniaudio in this repo has no ASIO backend symbol.
    // Treat "asio" as preferred low-latency intent and fall back to WASAPI.
    if (strcmp(name, "asio") == 0) return ma_backend_wasapi;
    if (strcmp(name, "directsound") == 0 || strcmp(name, "dsound") == 0) return ma_backend_dsound;
    if (strcmp(name, "aaudio") == 0) return ma_backend_aaudio;
    if (strcmp(name, "opensl") == 0 || strcmp(name, "opensles") == 0) return ma_backend_opensl;
    return ma_backend_null;
}

static int contains_backend(const ma_backend* list, int count, ma_backend backend) {
    for (int i = 0; i < count; i++) {
        if (list[i] == backend) return 1;
    }
    return 0;
}

static int default_backend_order(ma_backend* out, int max_count) {
    int c = 0;
    if (max_count <= 0) return 0;
#if defined(__linux__)
    if (c < max_count) out[c++] = ma_backend_jack;
    if (c < max_count) out[c++] = ma_backend_pulseaudio;
    if (c < max_count) out[c++] = ma_backend_alsa;
#elif defined(__APPLE__)
    if (c < max_count) out[c++] = ma_backend_jack;
    if (c < max_count) out[c++] = ma_backend_coreaudio;
#elif defined(_WIN32)
    if (c < max_count) out[c++] = ma_backend_wasapi;
    if (c < max_count) out[c++] = ma_backend_dsound;
    if (c < max_count) out[c++] = ma_backend_winmm;
#elif defined(__ANDROID__)
    if (c < max_count) out[c++] = ma_backend_aaudio;
    if (c < max_count) out[c++] = ma_backend_opensl;
#endif
    return c;
}

static int parse_backend_order(ma_backend* out, int max_count) {
    const char* env = getenv("STAGESYNC_AUDIO_BACKENDS");
    int count = 0;

    if (env && env[0] != '\0') {
        char tmp[256];
        strncpy(tmp, env, sizeof(tmp) - 1);
        tmp[sizeof(tmp) - 1] = '\0';

        char* token = strtok(tmp, ",; ");
        while (token && count < max_count) {
            for (int i = 0; token[i] != '\0'; i++) {
                token[i] = (char)tolower((unsigned char)token[i]);
            }
            ma_backend b = backend_from_name(token);
            if (b != ma_backend_null && !contains_backend(out, count, b)) {
                out[count++] = b;
            }
            token = strtok(NULL, ",; ");
        }
    }

    if (count == 0) {
        count = default_backend_order(out, max_count);
    }

    return count;
}

static DeviceEntry* find_device_entry(int32_t public_index) {
    for (int32_t i = 0; i < g_device_count; i++) {
        if (g_devices[i].index == public_index) return &g_devices[i];
    }
    return NULL;
}

static void refresh_device_catalog(void) {
    g_device_count = 0;
    memset(g_devices, 0, sizeof(g_devices));

    ma_backend order[8];
    int backend_count = parse_backend_order(order, (int)(sizeof(order) / sizeof(order[0])));

    for (int b = 0; b < backend_count; b++) {
        ma_backend backend = order[b];
        ma_context ctx;
        if (ma_context_init(&backend, 1, NULL, &ctx) != MA_SUCCESS) {
            continue;
        }

        ma_device_info* pPlayback = NULL;
        ma_uint32 playbackCount = 0;
        if (ma_context_get_devices(&ctx, &pPlayback, &playbackCount, NULL, NULL) == MA_SUCCESS) {
            for (ma_uint32 i = 0; i < playbackCount && g_device_count < MAX_DEVICE_CATALOG; i++) {
                DeviceEntry* e = &g_devices[g_device_count];
                e->index = g_device_count;
                e->backend = backend;
                e->device_id = pPlayback[i].id;
                strncpy(e->name, pPlayback[i].name, sizeof(e->name) - 1);
                e->name[sizeof(e->name) - 1] = '\0';
                e->is_default = pPlayback[i].isDefault ? 1 : 0;
                g_device_count++;
            }
        }

        ma_context_uninit(&ctx);
    }

    if (g_device_count == 0) {
        ma_context ctx;
        if (ma_context_init(NULL, 0, NULL, &ctx) == MA_SUCCESS) {
            ma_device_info* pPlayback = NULL;
            ma_uint32 playbackCount = 0;
            if (ma_context_get_devices(&ctx, &pPlayback, &playbackCount, NULL, NULL) == MA_SUCCESS) {
                for (ma_uint32 i = 0; i < playbackCount && g_device_count < MAX_DEVICE_CATALOG; i++) {
                    DeviceEntry* e = &g_devices[g_device_count];
                    e->index = g_device_count;
                    e->backend = ctx.backend;
                    e->device_id = pPlayback[i].id;
                    strncpy(e->name, pPlayback[i].name, sizeof(e->name) - 1);
                    e->name[sizeof(e->name) - 1] = '\0';
                    e->is_default = pPlayback[i].isDefault ? 1 : 0;
                    g_device_count++;
                }
            }
            ma_context_uninit(&ctx);
        }
    }
}

// ── Lifecycle ─────────────────────────────────────────────────────────────────

int32_t ma_wrapper_init(int32_t device_index, uint32_t sample_rate, uint32_t channels) {
    if (g_engine_ready || g_context_ready || g_mutex_ready) {
        ma_wrapper_deinit();
    }

    ma_mutex_init(&g_mutex);
    g_mutex_ready = 1;
    memset(g_handles, 0, sizeof(g_handles));

    ma_engine_config cfg = ma_engine_config_init();
    cfg.sampleRate = sample_rate > 0 ? sample_rate : 48000;
    cfg.channels   = channels   > 0 ? channels   : 2;

    ma_device_id selected_device_id;
    int has_selected_device = 0;

    if (device_index >= 0) {
        refresh_device_catalog();
        DeviceEntry* entry = find_device_entry(device_index);
        if (entry) {
            ma_backend backend = entry->backend;
            if (ma_context_init(&backend, 1, NULL, &g_context) == MA_SUCCESS) {
                g_context_ready = 1;
                g_current_backend = backend;
                selected_device_id = entry->device_id;
                cfg.pPlaybackDeviceID = &selected_device_id;
                cfg.pContext = &g_context;
                has_selected_device = 1;
            }
        }
    }

    if (!g_context_ready) {
        ma_backend order[8];
        int backend_count = parse_backend_order(order, (int)(sizeof(order) / sizeof(order[0])));
        ma_result ctx_result = MA_ERROR;
        if (backend_count > 0) {
            ctx_result = ma_context_init(order, (ma_uint32)backend_count, NULL, &g_context);
        }
        if (ctx_result != MA_SUCCESS) {
            ctx_result = ma_context_init(NULL, 0, NULL, &g_context);
        }
        if (ctx_result == MA_SUCCESS) {
            g_context_ready = 1;
            g_current_backend = g_context.backend;
            cfg.pContext = &g_context;
        }
    }

    ma_result result = ma_engine_init(&cfg, &g_engine);
    if (result != MA_SUCCESS) {
        if (g_context_ready) {
            ma_context_uninit(&g_context);
            g_context_ready = 0;
        }
        if (g_mutex_ready) {
            ma_mutex_uninit(&g_mutex);
            g_mutex_ready = 0;
        }
        return (int32_t)result;
    }

    g_engine_ready = 1;
    g_current_device_index = has_selected_device ? device_index : -1;
    return 0;
}

void ma_wrapper_deinit(void) {
    if (g_mutex_ready) {
        ma_mutex_lock(&g_mutex);
        for (int i = 0; i < MAX_HANDLES; i++) {
            if (g_handles[i].active) free_handle(&g_handles[i]);
        }
        ma_mutex_unlock(&g_mutex);
    }

    if (g_engine_ready) {
        ma_engine_uninit(&g_engine);
    }
    if (g_context_ready) {
        ma_context_uninit(&g_context);
    }
    if (g_mutex_ready) {
        ma_mutex_uninit(&g_mutex);
    }

    g_engine_ready = 0;
    g_context_ready = 0;
    g_mutex_ready = 0;
    g_current_device_index = -1;
    g_current_backend = ma_backend_null;
}

// ── Device management ─────────────────────────────────────────────────────────

char* ma_wrapper_list_devices(void) {
    refresh_device_catalog();

    // Each entry: ~320 bytes worst case for name + JSON overhead.
    size_t buf_size = 2 + (size_t)g_device_count * 320 + 4;
    char* buf = (char*)malloc(buf_size);
    if (!buf) {
        return NULL;
    }

    int pos = 0;
    buf[pos++] = '[';
    for (int32_t i = 0; i < g_device_count; i++) {
        if (i > 0) buf[pos++] = ',';
        // Escape double quotes in device name.
        char escaped[256] = {0};
        int ei = 0;
        const char* n = g_devices[i].name;
        for (int ni = 0; n[ni] && ei < 250; ni++) {
            if (n[ni] == '"' || n[ni] == '\\') escaped[ei++] = '\\';
            escaped[ei++] = n[ni];
        }
        const char* backend_name = backend_to_name(g_devices[i].backend);
        pos += snprintf(buf + pos, buf_size - (size_t)pos,
            "{\"index\":%d,\"name\":\"%s\",\"backend\":\"%s\",\"isDefault\":%s}",
            g_devices[i].index, escaped, backend_name, g_devices[i].is_default ? "true" : "false");
    }
    buf[pos++] = ']';
    buf[pos]   = '\0';
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
    if (!g_engine_ready || !g_mutex_ready || !cue_id || !file_path) return -1;

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
    if (!g_mutex_ready || !cue_id) return;
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
    if (!g_engine_ready || !g_mutex_ready || !cue_id) return -1;

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
    if (!g_mutex_ready || !cue_id) return;
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
    if (!g_mutex_ready || !cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) ma_sound_stop(&h->sound);
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_resume(const char* cue_id) {
    if (!g_mutex_ready || !cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) ma_sound_start(&h->sound);
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_stop_all(void) {
    if (!g_engine_ready || !g_mutex_ready) return;
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
