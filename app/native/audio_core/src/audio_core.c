/*
 * Implementación del núcleo de audio dúplex (F2-02).
 *
 * El callback de miniaudio no toma cerrojos ni reserva memoria: copia entre
 * los búferes circulares SPSC de miniaudio y actualiza contadores atómicos.
 */
#include "audio_core.h"

#include <stdlib.h>
#include <string.h>

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

struct ac_engine {
  ma_context context;
  int context_ready;

  ma_device device;
  int device_ready;
  int running;

  ma_pcm_rb playback_rb; /* productor: Dart; consumidor: callback */
  int playback_rb_ready;
  ma_pcm_rb capture_rb;  /* productor: callback; consumidor: Dart */
  int capture_rb_ready;

  /* Contadores atómicos: los macros ma_atomic_* exigen ma_uint64 volátil. */
  volatile ma_uint64 samples_processed;
  volatile ma_uint64 playback_underrun_frames;
  volatile ma_uint64 capture_overrun_frames;
};

static void on_audio(ma_device *device, void *output, const void *input, ma_uint32 frames) {
  ac_engine *e = (ac_engine *)device->pUserData;
  float *dst = (float *)output;
  const float *src = (const float *)input;
  ma_uint32 done;

  /* Reproducción: lo que no hay en el búfer sale como silencio. */
  done = 0;
  while (done < frames) {
    ma_uint32 want = frames - done;
    void *block = NULL;
    if (ma_pcm_rb_acquire_read(&e->playback_rb, &want, &block) != MA_SUCCESS || want == 0) {
      break;
    }
    memcpy(dst + done, block, want * sizeof(float));
    ma_pcm_rb_commit_read(&e->playback_rb, want);
    done += want;
  }
  if (done < frames) {
    memset(dst + done, 0, (frames - done) * sizeof(float));
    ma_atomic_fetch_add_explicit_64(&e->playback_underrun_frames, frames - done,
                                    ma_atomic_memory_order_relaxed);
  }

  /* Captura: lo que no cabe se descarta y se cuenta. */
  if (src != NULL) {
    done = 0;
    while (done < frames) {
      ma_uint32 want = frames - done;
      void *block = NULL;
      if (ma_pcm_rb_acquire_write(&e->capture_rb, &want, &block) != MA_SUCCESS || want == 0) {
        break;
      }
      memcpy(block, src + done, want * sizeof(float));
      ma_pcm_rb_commit_write(&e->capture_rb, want);
      done += want;
    }
    if (done < frames) {
      ma_atomic_fetch_add_explicit_64(&e->capture_overrun_frames, frames - done,
                                      ma_atomic_memory_order_relaxed);
    }
  }

  ma_atomic_fetch_add_explicit_64(&e->samples_processed, frames, ma_atomic_memory_order_relaxed);
}

ac_status ac_open(const ac_config *config, ac_engine **out) {
  ac_engine *e;
  ma_backend null_backend = ma_backend_null;
  ma_device_config dc;
  uint32_t rate;
  uint32_t playback_frames;
  uint32_t capture_frames;

  if (config == NULL || out == NULL) return AC_ERR_ARG;
  *out = NULL;

  e = (ac_engine *)calloc(1, sizeof *e);
  if (e == NULL) return AC_ERR_INIT;

  if (ma_context_init(config->use_null_backend ? &null_backend : NULL,
                      config->use_null_backend ? 1u : 0u, NULL, &e->context) != MA_SUCCESS) {
    free(e);
    return AC_ERR_INIT;
  }
  e->context_ready = 1;

  dc = ma_device_config_init(ma_device_type_duplex);
  dc.capture.format = ma_format_f32;
  dc.capture.channels = 1;
  dc.playback.format = ma_format_f32;
  dc.playback.channels = 1;
  dc.sampleRate = config->sample_rate;
  dc.periodSizeInFrames = config->period_frames;
  dc.performanceProfile = ma_performance_profile_low_latency;
  dc.dataCallback = on_audio;
  dc.pUserData = e;

  if (ma_device_init(&e->context, &dc, &e->device) != MA_SUCCESS) {
    ac_close(e);
    return AC_ERR_DEVICE;
  }
  e->device_ready = 1;

  rate = e->device.sampleRate;
  playback_frames = config->playback_capacity != 0 ? config->playback_capacity : rate;
  capture_frames = config->capture_capacity != 0 ? config->capture_capacity : rate;

  if (ma_pcm_rb_init(ma_format_f32, 1, playback_frames, NULL, NULL, &e->playback_rb) != MA_SUCCESS) {
    ac_close(e);
    return AC_ERR_INIT;
  }
  e->playback_rb_ready = 1;

  if (ma_pcm_rb_init(ma_format_f32, 1, capture_frames, NULL, NULL, &e->capture_rb) != MA_SUCCESS) {
    ac_close(e);
    return AC_ERR_INIT;
  }
  e->capture_rb_ready = 1;

  *out = e;
  return AC_OK;
}

ac_status ac_start(ac_engine *engine) {
  if (engine == NULL) return AC_ERR_ARG;
  if (!engine->device_ready) return AC_ERR_STATE;
  if (engine->running) return AC_ERR_STATE;
  if (ma_device_start(&engine->device) != MA_SUCCESS) return AC_ERR_DEVICE;
  engine->running = 1;
  return AC_OK;
}

ac_status ac_stop(ac_engine *engine) {
  if (engine == NULL) return AC_ERR_ARG;
  if (!engine->running) return AC_ERR_STATE;
  if (ma_device_stop(&engine->device) != MA_SUCCESS) return AC_ERR_DEVICE;
  engine->running = 0;
  return AC_OK;
}

void ac_close(ac_engine *engine) {
  if (engine == NULL) return;
  if (engine->running) {
    ma_device_stop(&engine->device);
    engine->running = 0;
  }
  if (engine->capture_rb_ready) ma_pcm_rb_uninit(&engine->capture_rb);
  if (engine->playback_rb_ready) ma_pcm_rb_uninit(&engine->playback_rb);
  if (engine->device_ready) ma_device_uninit(&engine->device);
  if (engine->context_ready) ma_context_uninit(&engine->context);
  free(engine);
}

ac_status ac_get_info(const ac_engine *engine, ac_info *out) {
  if (engine == NULL || out == NULL) return AC_ERR_ARG;
  if (!engine->device_ready) return AC_ERR_STATE;
  out->sample_rate = engine->device.sampleRate;
  out->channels = 1;
  out->input_latency_frames =
      engine->device.capture.internalPeriodSizeInFrames * engine->device.capture.internalPeriods;
  out->output_latency_frames =
      engine->device.playback.internalPeriodSizeInFrames * engine->device.playback.internalPeriods;
  return AC_OK;
}

uint64_t ac_sample_counter(const ac_engine *engine) {
  if (engine == NULL) return 0;
  return ma_atomic_load_explicit_64(&engine->samples_processed, ma_atomic_memory_order_relaxed);
}

uint32_t ac_write_playback(ac_engine *engine, const float *samples, uint32_t frames) {
  uint32_t done = 0;
  if (engine == NULL || samples == NULL || !engine->playback_rb_ready) return 0;
  while (done < frames) {
    ma_uint32 want = frames - done;
    void *block = NULL;
    if (ma_pcm_rb_acquire_write(&engine->playback_rb, &want, &block) != MA_SUCCESS || want == 0) {
      break;
    }
    memcpy(block, samples + done, want * sizeof(float));
    ma_pcm_rb_commit_write(&engine->playback_rb, want);
    done += want;
  }
  return done;
}

uint32_t ac_playback_pending(const ac_engine *engine) {
  if (engine == NULL || !engine->playback_rb_ready) return 0;
  return ma_pcm_rb_available_read((ma_pcm_rb *)&engine->playback_rb);
}

uint32_t ac_read_capture(ac_engine *engine, float *dst, uint32_t max_frames) {
  uint32_t done = 0;
  if (engine == NULL || dst == NULL || !engine->capture_rb_ready) return 0;
  while (done < max_frames) {
    ma_uint32 want = max_frames - done;
    void *block = NULL;
    if (ma_pcm_rb_acquire_read(&engine->capture_rb, &want, &block) != MA_SUCCESS || want == 0) {
      break;
    }
    memcpy(dst + done, block, want * sizeof(float));
    ma_pcm_rb_commit_read(&engine->capture_rb, want);
    done += want;
  }
  return done;
}

uint64_t ac_playback_underrun_frames(const ac_engine *engine) {
  if (engine == NULL) return 0;
  return ma_atomic_load_explicit_64(&engine->playback_underrun_frames, ma_atomic_memory_order_relaxed);
}

uint64_t ac_capture_overrun_frames(const ac_engine *engine) {
  if (engine == NULL) return 0;
  return ma_atomic_load_explicit_64(&engine->capture_overrun_frames, ma_atomic_memory_order_relaxed);
}
