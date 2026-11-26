/*
 * Medición del criterio 1 (F2-02): detección de clics y comparación de instantes.
 * Funciones puras; no toca el audio.
 */
#include "audio_medicion.h"

#include <stdlib.h>

uint32_t am_detect_onsets(const float *x, uint32_t n, float threshold,
                          uint32_t refractory, uint32_t *out, uint32_t max_out) {
  uint32_t i;
  uint32_t found = 0;
  uint32_t quiet_until = 0; /* índice desde el que se admite un nuevo disparo */

  if (x == NULL || out == NULL || n == 0 || max_out == 0) return 0;

  for (i = 0; i < n && found < max_out; i++) {
    float a = x[i] < 0 ? -x[i] : x[i];
    if (i < quiet_until || a < threshold) continue;
    out[found++] = i;
    quiet_until = i + refractory;
  }
  return found;
}

static int64_t signed_diff(uint64_t later, uint64_t earlier) {
  return (int64_t)(later - earlier);
}

static void sort_doubles(double *v, uint32_t n) {
  uint32_t i, j;
  for (i = 1; i < n; i++) {
    double key = v[i];
    j = i;
    while (j > 0 && v[j - 1] > key) {
      v[j] = v[j - 1];
      j--;
    }
    v[j] = key;
  }
}

am_status am_latency_report(const uint64_t *emitted, uint32_t n_emitted,
                            const uint64_t *detected, uint32_t n_detected,
                            uint32_t sample_rate, am_report *out) {
  double *delay_ms;
  double median;
  double sum_err = 0.0;
  double max_err = 0.0;
  uint32_t i;
  uint32_t n = n_emitted;
  double ms_per_sample;

  if (emitted == NULL || detected == NULL || out == NULL || n == 0 || sample_rate == 0) {
    return AM_ERR_ARG;
  }
  if (n_detected != n_emitted) return AM_ERR_COUNT;

  ms_per_sample = 1000.0 / (double)sample_rate;
  delay_ms = (double *)malloc(n * sizeof *delay_ms);
  if (delay_ms == NULL) return AM_ERR_MEM;

  for (i = 0; i < n; i++) {
    delay_ms[i] = (double)signed_diff(detected[i], emitted[i]) * ms_per_sample;
  }

  /* La mediana de una lista par es la media de sus dos centrales. */
  sort_doubles(delay_ms, n);
  if (n % 2 == 1) {
    median = delay_ms[n / 2];
  } else {
    median = 0.5 * (delay_ms[n / 2 - 1] + delay_ms[n / 2]);
  }

  for (i = 0; i < n; i++) {
    double err = delay_ms[i] - median;
    if (err < 0) err = -err;
    sum_err += err;
    if (err > max_err) max_err = err;
  }

  out->pairs = n;
  out->latency_ms = median;
  out->max_error_ms = max_err;
  out->mean_error_ms = sum_err / (double)n;
  out->pass = max_err <= AM_UMBRAL_ERROR_MS ? 1 : 0;

  free(delay_ms);
  return AM_OK;
}
