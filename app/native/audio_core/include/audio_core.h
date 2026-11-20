/*
 * audio_core: núcleo de audio dúplex del cliente (F2-02).
 *
 * Un solo flujo dúplex sobre miniaudio. El hilo nativo escribe la captura en
 * un búfer circular y lee la reproducción de otro; Dart solo lee y escribe
 * fuera del hilo de audio. Un flujo por instancia.
 *
 * Hilos: ac_open, ac_start, ac_stop y ac_close se llaman desde un solo hilo.
 * ac_write_playback y ac_read_capture son el productor y el consumidor de sus
 * búferes, y pueden llamarse desde otro hilo a la vez. Los contadores se leen
 * en cualquier momento.
 */
#ifndef AUDIO_CORE_H
#define AUDIO_CORE_H

#include <stdint.h>

#if defined(_WIN32)
#  if defined(AUDIO_CORE_BUILD)
#    define AC_API __declspec(dllexport)
#  else
#    define AC_API __declspec(dllimport)
#  endif
#else
#  define AC_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ac_engine ac_engine;

typedef enum {
  AC_OK = 0,
  AC_ERR_ARG = -1,    /* argumento nulo o inválido */
  AC_ERR_INIT = -2,   /* no se pudo iniciar el contexto de audio */
  AC_ERR_DEVICE = -3, /* no se pudo abrir o arrancar el dispositivo */
  AC_ERR_STATE = -4   /* operación no válida en el estado actual */
} ac_status;

typedef struct {
  uint32_t sample_rate;       /* 0: frecuencia nativa del dispositivo */
  uint32_t period_frames;     /* 0: periodo por omisión de miniaudio */
  uint32_t playback_capacity; /* frames del búfer de reproducción; 0: 1 s */
  uint32_t capture_capacity;  /* frames del búfer de captura; 0: 1 s */
  int32_t use_null_backend;   /* 1: backend nulo; solo para pruebas */
} ac_config;

typedef struct {
  uint32_t sample_rate;       /* frecuencia real del flujo */
  uint32_t channels;          /* siempre 1 en esta versión (mono) */
  uint32_t input_latency_frames;
  uint32_t output_latency_frames;
} ac_info;

/* Abre el flujo dúplex en parado. */
AC_API ac_status ac_open(const ac_config *config, ac_engine **out);
AC_API ac_status ac_start(ac_engine *engine);
AC_API ac_status ac_stop(ac_engine *engine);
AC_API void ac_close(ac_engine *engine);
AC_API ac_status ac_get_info(const ac_engine *engine, ac_info *out);

/* Frames procesados por el hilo nativo desde ac_start. Crece solo en marcha. */
AC_API uint64_t ac_sample_counter(const ac_engine *engine);

/* Encola hasta `frames` muestras para reproducir. Devuelve las aceptadas. */
AC_API uint32_t ac_write_playback(ac_engine *engine, const float *samples, uint32_t frames);
AC_API uint32_t ac_playback_pending(const ac_engine *engine);

/* Copia la captura disponible, hasta `max_frames`. Devuelve los frames copiados. */
AC_API uint32_t ac_read_capture(ac_engine *engine, float *dst, uint32_t max_frames);

/* Frames de silencio emitidos por falta de reproducción, y frames de captura
 * descartados porque nadie los leyó a tiempo. */
AC_API uint64_t ac_playback_underrun_frames(const ac_engine *engine);
AC_API uint64_t ac_capture_overrun_frames(const ac_engine *engine);

#ifdef __cplusplus
}
#endif

#endif /* AUDIO_CORE_H */
