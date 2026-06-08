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
    int          active;         /* 1 = in use */
    int          initialised;    /* ma_sound_init called */
    float        volume_linear;  /* last set playback volume (for resume fade) */
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
    if (strcmp(name, "asio") == 0) {
        /* miniaudio 0.11.x has no native ASIO backend — map to WASAPI */
        return ma_backend_wasapi;
    }
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

/* Replace any byte that would produce invalid UTF-8 in JSON with '?'.
   Handles incomplete multi-byte sequences and lone continuation bytes. */
static void sanitize_utf8(char* s, size_t max_bytes) {
    size_t i = 0;
    size_t len = strnlen(s, max_bytes);
    while (i < len) {
        unsigned char c = (unsigned char)s[i];
        int seq = 0;
        if      (c < 0x80)              { i++;    continue; }  /* ASCII */
        else if ((c & 0xE0) == 0xC0)   seq = 2;
        else if ((c & 0xF0) == 0xE0)   seq = 3;
        else if ((c & 0xF8) == 0xF0)   seq = 4;
        else                            { s[i++] = '?'; continue; } /* bare continuation */

        if (i + (size_t)seq > len) { /* truncated sequence — replace leader + rest */
            for (size_t j = i; j < len; j++) s[j] = '?';
            break;
        }
        int ok = 1;
        for (int k = 1; k < seq; k++)
            if (((unsigned char)s[i + k] & 0xC0) != 0x80) { ok = 0; break; }
        if (!ok) { s[i++] = '?'; continue; }
        i += (size_t)seq;
    }
}

char* ma_wrapper_list_devices(void) {
    refresh_device_catalog();

    /* 640 bytes per entry: 512 for name (worst-case escaped) + JSON wrapper */
    size_t buf_size = 4 + (size_t)g_device_count * 640 + 4;
    char* buf = (char*)malloc(buf_size);
    if (!buf) return NULL;

    size_t pos = 0;
    buf[pos++] = '[';
    for (int32_t i = 0; i < g_device_count; i++) {
        if (i > 0) buf[pos++] = ',';

        /* Copy and sanitize device name before escaping. */
        char name_clean[256];
        strncpy(name_clean, g_devices[i].name, sizeof(name_clean) - 1);
        name_clean[sizeof(name_clean) - 1] = '\0';
        sanitize_utf8(name_clean, sizeof(name_clean));

        /* JSON-escape: backslash and double-quote only (sanitize_utf8 already
           removed invalid UTF-8, so no other escaping is needed for JSON). */
        char escaped[512] = {0};
        int ei = 0;
        for (int ni = 0; name_clean[ni] && ei < 506; ni++) {
            if (name_clean[ni] == '"' || name_clean[ni] == '\\')
                escaped[ei++] = '\\';
            escaped[ei++] = name_clean[ni];
        }
        /* Trim any partial UTF-8 sequence introduced by the 506-byte cut. */
        while (ei > 0 && ((unsigned char)escaped[ei - 1] & 0xC0) == 0x80) ei--;
        escaped[ei] = '\0';

        const char* backend_name = backend_to_name(g_devices[i].backend);
        int written = snprintf(buf + pos, buf_size - pos,
            "{\"index\":%d,\"name\":\"%s\",\"backend\":\"%s\",\"isDefault\":%s}",
            g_devices[i].index, escaped, backend_name,
            g_devices[i].is_default ? "true" : "false");
        if (written > 0) pos += (size_t)written;
    }
    if (pos < buf_size - 2) {
        buf[pos++] = ']';
        buf[pos]   = '\0';
    }
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

    /* MA_SOUND_FLAG_DECODE would decode the whole file to RAM here — that takes
       100–400 ms for a typical MP3 and causes audible delay on Go.
       Streaming mode (no DECODE flag) opens the file and fills a ring buffer
       in a background thread instead. On any local SSD this is transparent. */
    ma_result r = ma_sound_init_from_file(&g_engine, file_path,
        MA_SOUND_FLAG_NO_SPATIALIZATION,
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
    int32_t     loop,
    float       start_time_ms,
    float       end_time_ms)
{
    if (!g_engine_ready || !g_mutex_ready || !cue_id) return -1;

    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (!h || !h->initialised) { ma_mutex_unlock(&g_mutex); return -1; }

    uint32_t sr = ma_engine_get_sample_rate(&g_engine);

    /* ── Volume ─────────────────────────────────────────────────────────── */
    float linear_vol = (volume_db <= -100.0f) ? 0.0f : powf(10.0f, volume_db / 20.0f);
    ma_sound_set_volume(&h->sound, linear_vol);
    h->volume_linear = linear_vol;
    ma_sound_set_looping(&h->sound, loop ? MA_TRUE : MA_FALSE);

    if (fade_in_ms > 0.0f)
        ma_sound_set_fade_in_milliseconds(&h->sound, 0.0f, linear_vol, (ma_uint64)fade_in_ms);

    /* ── File start position ─────────────────────────────────────────────── */
    ma_uint64 start_file_frames = 0;
    if (start_time_ms > 0.0f) {
        start_file_frames = (ma_uint64)((double)start_time_ms * sr / 1000.0);
        ma_sound_seek_to_pcm_frame(&h->sound, start_file_frames);
    }

    /* ── Timestamp scheduling / late-join compensation ───────────────────── */
    ma_uint64 engine_start_frame = ma_engine_get_time_in_pcm_frames(&g_engine);
    double    late_ms            = 0.0;   /* how many ms we are past the intended start */

    if (start_unix_ms > 0) {
        int64_t now_ms = now_unix_ms();
        int64_t delta  = start_unix_ms - now_ms;

        if (delta > 0) {
            /* Future: schedule start */
            ma_uint64 delay_frames = (ma_uint64)((double)delta * sr / 1000.0);
            engine_start_frame += delay_frames;
            ma_sound_set_start_time_in_pcm_frames(&h->sound, engine_start_frame);
        } else if (delta < -50) {
            /* Past by > 50 ms: seek further into file to align timeline */
            late_ms = (double)(-delta);
            ma_uint64 offset_frames = (ma_uint64)(late_ms * sr / 1000.0);
            ma_sound_seek_to_pcm_frame(&h->sound, start_file_frames + offset_frames);
        }
    }

    /* ── End time / scheduled stop ───────────────────────────────────────── */
    if (end_time_ms > 0.0f) {
        double play_from_ms  = (start_time_ms > 0.0f ? start_time_ms : 0.0f) + late_ms;
        double remaining_ms  = (double)end_time_ms - play_from_ms;

        if (remaining_ms <= 0.0) {
            /* Already past the end — do not start */
            ma_mutex_unlock(&g_mutex);
            return 0;
        }

        ma_uint64 remaining_frames = (ma_uint64)(remaining_ms * sr / 1000.0);

        if (fade_out_ms > 0.0f && remaining_ms > fade_out_ms) {
            /* Schedule fade-out to start before hard stop */
            ma_uint64 fade_frames  = (ma_uint64)((double)fade_out_ms * sr / 1000.0);
            ma_uint64 fade_engine  = engine_start_frame + remaining_frames - fade_frames;
            ma_uint64 stop_engine  = engine_start_frame + remaining_frames;
            /* miniaudio has no "start fade at engine time T" API, so we approximate:
               if the fade start is already past, begin the fade immediately. */
            ma_uint64 now_engine = ma_engine_get_time_in_pcm_frames(&g_engine);
            if (fade_engine <= now_engine) {
                float cur_vol = ma_sound_get_volume(&h->sound);
                ma_sound_set_fade_in_milliseconds(&h->sound, cur_vol, 0.0f, (ma_uint64)fade_out_ms);
            } else {
                /* Store the stop time; the fade-out will be applied by the server
                   via ma_wrapper_fade_volume() at the appropriate moment. */
                (void)fade_engine; /* suppress unused warning */
            }
            ma_sound_set_stop_time_in_pcm_frames(&h->sound, stop_engine);
        } else {
            ma_sound_set_stop_time_in_pcm_frames(&h->sound,
                engine_start_frame + remaining_frames);
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

void ma_wrapper_set_master_volume(float volume_db) {
    if (!g_engine_ready) return;
    float linear = (volume_db <= -100.0f) ? 0.0f : powf(10.0f, volume_db / 20.0f);
    ma_engine_set_volume(&g_engine, linear);
}

void ma_wrapper_pause(const char* cue_id, float fade_ms) {
    if (!g_mutex_ready || !cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) {
        if (fade_ms > 0.0f && g_engine_ready) {
            float cur_vol = ma_sound_get_volume(&h->sound);
            ma_sound_set_fade_in_milliseconds(&h->sound, cur_vol, 0.0f, (ma_uint64)fade_ms);
            uint32_t  sr           = ma_engine_get_sample_rate(&g_engine);
            ma_uint64 engine_time  = ma_engine_get_time_in_pcm_frames(&g_engine);
            ma_uint64 fade_frames  = (ma_uint64)((double)fade_ms * sr / 1000.0);
            /* ma_sound_stop() after the fade (doesn't reset playhead = true pause) */
            ma_sound_set_stop_time_in_pcm_frames(&h->sound, engine_time + fade_frames);
        } else {
            ma_sound_stop(&h->sound);
        }
    }
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_resume(const char* cue_id, float fade_ms) {
    if (!g_mutex_ready || !cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) {
        /* Clear any pending stop time from the pause fade */
        ma_sound_set_stop_time_in_pcm_frames(&h->sound, (~(ma_uint64)0));
        if (fade_ms > 0.0f) {
            float target = h->volume_linear > 0.0f ? h->volume_linear : 1.0f;
            ma_sound_set_volume(&h->sound, 0.0f);
            ma_sound_set_fade_in_milliseconds(&h->sound, 0.0f, target, (ma_uint64)fade_ms);
        }
        ma_sound_start(&h->sound);
    }
    ma_mutex_unlock(&g_mutex);
}

void ma_wrapper_fade_volume(
    const char* cue_id,
    float       target_db,
    float       duration_ms,
    int32_t     stop_when_done)
{
    if (!g_mutex_ready || !g_engine_ready || !cue_id) return;
    ma_mutex_lock(&g_mutex);
    Handle* h = find_handle(cue_id);
    if (h && h->initialised) {
        float cur_vol    = ma_sound_get_volume(&h->sound);
        float target_lin = (target_db <= -100.0f) ? 0.0f : powf(10.0f, target_db / 20.0f);
        ma_sound_set_fade_in_milliseconds(&h->sound, cur_vol, target_lin, (ma_uint64)duration_ms);
        h->volume_linear = target_lin;
        if (stop_when_done) {
            uint32_t  sr          = ma_engine_get_sample_rate(&g_engine);
            ma_uint64 engine_time = ma_engine_get_time_in_pcm_frames(&g_engine);
            ma_uint64 fade_frames = (ma_uint64)((double)duration_ms * sr / 1000.0);
            ma_sound_set_stop_time_in_pcm_frames(&h->sound, engine_time + fade_frames);
        }
    }
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

/* ── Silence detection ───────────────────────────────────────────────────────
   Scans the entire file as mono f32 PCM and finds the first/last frame whose
   peak amplitude exceeds threshold_db. Adds pad_ms of margin on both sides.
   Returns 0 on success, -1 on bad args, -2 if the file could not be opened.   */
int32_t ma_wrapper_detect_silence(
    const char* file_path,
    float       threshold_db,
    float       pad_ms,
    float*      out_start_ms,
    float*      out_end_ms)
{
    if (!file_path || !out_start_ms || !out_end_ms) return -1;
    *out_start_ms = 0.0f;
    *out_end_ms   = 0.0f;

    /* Decode to mono f32 at native sample rate for fast scanning */
    ma_decoder_config cfg = ma_decoder_config_init(ma_format_f32, 1, 0);
    ma_decoder decoder;
    if (ma_decoder_init_file(file_path, &cfg, &decoder) != MA_SUCCESS) return -2;

    float threshold_lin = (threshold_db <= -100.0f) ? 0.0f
                        : powf(10.0f, threshold_db / 20.0f);
    uint32_t sr = decoder.outputSampleRate;
    if (sr == 0) { ma_decoder_uninit(&decoder); return -2; }

#define SILENCE_CHUNK 2048
    float     buf[SILENCE_CHUNK];
    ma_uint64 total_frames       = 0;
    ma_uint64 first_nonsilent    = (ma_uint64)-1;
    ma_uint64 last_nonsilent     = 0;
    int       found_any          = 0;

    for (;;) {
        ma_uint64 frames_read = 0;
        ma_result r = ma_decoder_read_pcm_frames(&decoder, buf, SILENCE_CHUNK, &frames_read);
        if (frames_read == 0) break;

        for (ma_uint64 i = 0; i < frames_read; i++) {
            float s = buf[i] < 0.0f ? -buf[i] : buf[i];
            if (s >= threshold_lin) {
                ma_uint64 abs_frame = total_frames + i;
                if (!found_any || abs_frame < first_nonsilent)
                    first_nonsilent = abs_frame;
                last_nonsilent = abs_frame;
                found_any = 1;
            }
        }
        total_frames += frames_read;
        if (r != MA_SUCCESS) break; /* MA_AT_END or error */
    }
    ma_decoder_uninit(&decoder);

    double total_ms = (double)total_frames / sr * 1000.0;

    if (!found_any) {
        /* Completely silent — return full duration so caller can decide */
        *out_start_ms = 0.0f;
        *out_end_ms   = (float)total_ms;
        return 0;
    }

    double raw_start = (double)first_nonsilent / sr * 1000.0;
    double raw_end   = (double)last_nonsilent  / sr * 1000.0;

    double s = raw_start - pad_ms;
    double e = raw_end   + pad_ms;
    *out_start_ms = (float)(s < 0.0       ? 0.0       : s);
    *out_end_ms   = (float)(e > total_ms  ? total_ms  : e);
    return 0;
}

void ma_wrapper_free_string(char* str) {
    free(str);
}
