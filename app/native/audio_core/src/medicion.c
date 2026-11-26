/*
 * Medición del criterio 1 (F2-02). Pendiente de implementar: versión provisional
 * que no detecta nada y no compara nada, para que las pruebas queden en rojo.
 */
#include "audio_medicion.h"

uint32_t am_detect_onsets(const float *x, uint32_t n, float threshold,
                          uint32_t refractory, uint32_t *out, uint32_t max_out) {
  (void)x; (void)n; (void)threshold; (void)refractory; (void)out; (void)max_out;
  return 0;
}

am_status am_latency_report(const uint64_t *emitted, const uint64_t *detected,
                            uint32_t n, uint32_t sample_rate, am_report *out) {
  (void)emitted; (void)detected; (void)n; (void)sample_rate; (void)out;
  return AM_ERR_ARG;
}
