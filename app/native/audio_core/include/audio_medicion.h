/*
 * Medición del criterio 1 del POC (F2-02): arnés de bucle de retorno.
 *
 * Funciones puras, sin audio: detectan clics en una captura y comparan los
 * instantes de emisión conocidos con los instantes detectados. No forman parte
 * de la biblioteca que se entrega a la aplicación; solo las usan el ejecutable
 * de medición y sus pruebas.
 *
 * Todos los instantes son muestras contadas desde el inicio del flujo, el
 * mismo reloj que ac_sample_counter.
 */
#ifndef AUDIO_MEDICION_H
#define AUDIO_MEDICION_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Umbral del criterio 1: error de 50 ms o menos con audio sintético. */
#define AM_UMBRAL_ERROR_MS 50.0

typedef enum {
  AM_OK = 0,
  AM_ERR_ARG = -1,   /* argumento nulo, n = 0 o frecuencia no válida */
  AM_ERR_COUNT = -2, /* número de instantes emitidos y detectados distinto */
  AM_ERR_MEM = -3    /* no se pudo reservar memoria temporal */
} am_status;

typedef struct {
  uint32_t pairs;          /* pares comparados */
  double latency_ms;       /* mediana de la latencia de ida y vuelta */
  double max_error_ms;     /* mayor desviación respecto a esa mediana */
  double mean_error_ms;    /* desviación media respecto a esa mediana */
  int32_t pass;            /* 1 si max_error_ms <= AM_UMBRAL_ERROR_MS */
} am_report;

/* Detecta inicios de sonido: instantes en que |x| alcanza `threshold` tras al
 * menos `refractory` muestras sin disparo. Escribe hasta `max_out` índices en
 * `out` y devuelve cuántos encontró. Devuelve 0 con argumentos nulos. */
uint32_t am_detect_onsets(const float *x, uint32_t n, float threshold,
                          uint32_t refractory, uint32_t *out, uint32_t max_out);

/* Compara `n` instantes emitidos con los `n` detectados, en el mismo orden. La
 * latencia de ida y vuelta de cada par es detectado - emitido; el informe da la
 * mediana de esa latencia y el error de cada par frente a ella. */
am_status am_latency_report(const uint64_t *emitted, const uint64_t *detected,
                            uint32_t n, uint32_t sample_rate, am_report *out);

#ifdef __cplusplus
}
#endif

#endif /* AUDIO_MEDICION_H */
