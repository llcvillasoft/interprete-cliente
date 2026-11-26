/*
 * Pruebas de la medición del criterio 1 (F2-02). Sin audio: las señales son
 * sintéticas y sus instantes son conocidos, así que estas pruebas no sustituyen
 * la medición con la interfaz de audio en un equipo Windows.
 */
#include <stdio.h>
#include <string.h>

#include "audio_medicion.h"

static int g_run = 0;
static int g_failed = 0;

#define CHECK(cond)                                                          \
  do {                                                                       \
    g_run++;                                                                 \
    if (!(cond)) {                                                           \
      g_failed++;                                                            \
      fprintf(stderr, "%s:%d: falló: %s\n", __FILE__, __LINE__, #cond);      \
    }                                                                        \
  } while (0)

#define CHECK_NEAR(a, b, tol) CHECK(((a) - (b)) <= (tol) && ((b) - (a)) <= (tol))

#define SR 48000u

/* Pone un clic de `len` muestras de amplitud `amp` en `x` desde `at`. */
static void put_click(float *x, uint32_t n, uint32_t at, uint32_t len, float amp) {
  uint32_t i;
  for (i = 0; i < len && at + i < n; i++) x[at + i] = amp;
}

static void test_detects_clicks_at_known_positions(void) {
  float x[20000];
  uint32_t found[8];
  uint32_t n;
  memset(x, 0, sizeof x);
  put_click(x, 20000, 100, 48, 0.8f);
  put_click(x, 20000, 5000, 48, -0.8f);
  put_click(x, 20000, 9999, 48, 0.8f);

  n = am_detect_onsets(x, 20000, 0.3f, 2400, found, 8);
  CHECK(n == 3);
  if (n == 3) {
    CHECK(found[0] == 100);
    CHECK(found[1] == 5000);
    CHECK(found[2] == 9999);
  }
}

static void test_refractory_counts_one_click_once(void) {
  float x[4000];
  uint32_t found[4];
  memset(x, 0, sizeof x);
  /* Un clic de 48 muestras que oscila por encima del umbral cuenta una vez. */
  put_click(x, 4000, 1000, 48, 0.9f);
  CHECK(am_detect_onsets(x, 4000, 0.3f, 2400, found, 4) == 1);
}

static void test_silence_and_subthreshold_give_no_onsets(void) {
  float silence[1000];
  float quiet[1000];
  uint32_t found[4];
  uint32_t i;
  memset(silence, 0, sizeof silence);
  for (i = 0; i < 1000; i++) quiet[i] = (i % 2) ? 0.1f : -0.1f;
  CHECK(am_detect_onsets(silence, 1000, 0.3f, 100, found, 4) == 0);
  CHECK(am_detect_onsets(quiet, 1000, 0.3f, 100, found, 4) == 0);
}

static void test_detector_respects_max_out(void) {
  float x[4000];
  uint32_t found[2];
  memset(x, 0, sizeof x);
  put_click(x, 4000, 100, 4, 0.9f);
  put_click(x, 4000, 1000, 4, 0.9f);
  put_click(x, 4000, 2000, 4, 0.9f);
  CHECK(am_detect_onsets(x, 4000, 0.3f, 100, found, 2) == 2);
  CHECK(found[0] == 100);
  CHECK(found[1] == 1000);
}

static void test_detector_null_arguments_return_zero(void) {
  float x[4] = {0.9f, 0.0f, 0.0f, 0.0f};
  uint32_t found[2];
  CHECK(am_detect_onsets(NULL, 4, 0.3f, 1, found, 2) == 0);
  CHECK(am_detect_onsets(x, 4, 0.3f, 1, NULL, 2) == 0);
  CHECK(am_detect_onsets(x, 0, 0.3f, 1, found, 2) == 0);
}

static void test_constant_latency_has_zero_error(void) {
  uint64_t emitted[3] = {0, 24000, 48000};
  uint64_t detected[3] = {2000, 26000, 50000};
  am_report r;
  memset(&r, 0, sizeof r);

  CHECK(am_latency_report(emitted, detected, 3, SR, &r) == AM_OK);
  CHECK(r.pairs == 3);
  CHECK_NEAR(r.latency_ms, 2000.0 * 1000.0 / SR, 1e-9);
  CHECK_NEAR(r.max_error_ms, 0.0, 1e-9);
  CHECK_NEAR(r.mean_error_ms, 0.0, 1e-9);
  CHECK(r.pass == 1);
}

static void test_jitter_below_threshold_passes(void) {
  /* Latencias de 1000, 2000 y 3000 muestras: mediana 2000, error máximo de
   * 1000 muestras (20.8 ms). */
  uint64_t emitted[3] = {0, 24000, 48000};
  uint64_t detected[3] = {1000, 26000, 51000};
  am_report r;
  memset(&r, 0, sizeof r);

  CHECK(am_latency_report(emitted, detected, 3, SR, &r) == AM_OK);
  CHECK_NEAR(r.max_error_ms, 1000.0 * 1000.0 / SR, 1e-9);
  CHECK(r.pass == 1);
}

static void test_error_above_threshold_fails(void) {
  /* Una latencia desviada 3000 muestras (62.5 ms) hace fallar el criterio. */
  uint64_t emitted[3] = {0, 24000, 48000};
  uint64_t detected[3] = {2000, 26000, 53000};
  am_report r;
  memset(&r, 0, sizeof r);

  CHECK(am_latency_report(emitted, detected, 3, SR, &r) == AM_OK);
  CHECK(r.max_error_ms > AM_UMBRAL_ERROR_MS);
  CHECK(r.pass == 0);
}

static void test_error_exactly_at_threshold_passes(void) {
  /* 2400 muestras a 48 kHz son 50 ms: el umbral es «50 ms o menos». */
  uint64_t emitted[4] = {0, 24000, 48000, 72000};
  uint64_t detected[4] = {0, 24000, 48000, 74400};
  am_report r;
  memset(&r, 0, sizeof r);

  CHECK(am_latency_report(emitted, detected, 4, SR, &r) == AM_OK);
  CHECK_NEAR(r.max_error_ms, AM_UMBRAL_ERROR_MS, 1e-9);
  CHECK(r.pass == 1);
}

static void test_median_of_even_count_is_mean_of_middle_pair(void) {
  /* Latencias 100, 200, 300, 400: la mediana es 250 muestras. */
  uint64_t emitted[4] = {0, 1000, 2000, 3000};
  uint64_t detected[4] = {100, 1200, 2300, 3400};
  am_report r;
  memset(&r, 0, sizeof r);

  CHECK(am_latency_report(emitted, detected, 4, SR, &r) == AM_OK);
  CHECK_NEAR(r.latency_ms, 250.0 * 1000.0 / SR, 1e-9);
}

static void test_count_mismatch_is_reported(void) {
  uint64_t emitted[3] = {0, 24000, 48000};
  uint64_t detected[2] = {2000, 26000};
  am_report r;
  CHECK(am_latency_report(emitted, detected, 3, SR, &r) == AM_ERR_COUNT);
}

static void test_report_rejects_bad_arguments(void) {
  uint64_t emitted[1] = {0};
  uint64_t detected[1] = {0};
  am_report r;
  CHECK(am_latency_report(NULL, detected, 1, SR, &r) == AM_ERR_ARG);
  CHECK(am_latency_report(emitted, NULL, 1, SR, &r) == AM_ERR_ARG);
  CHECK(am_latency_report(emitted, detected, 1, SR, NULL) == AM_ERR_ARG);
  CHECK(am_latency_report(emitted, detected, 0, SR, &r) == AM_ERR_ARG);
  CHECK(am_latency_report(emitted, detected, 1, 0, &r) == AM_ERR_ARG);
}

int main(void) {
  test_detects_clicks_at_known_positions();
  test_refractory_counts_one_click_once();
  test_silence_and_subthreshold_give_no_onsets();
  test_detector_respects_max_out();
  test_detector_null_arguments_return_zero();
  test_constant_latency_has_zero_error();
  test_jitter_below_threshold_passes();
  test_error_above_threshold_fails();
  test_error_exactly_at_threshold_passes();
  test_median_of_even_count_is_mean_of_middle_pair();
  test_count_mismatch_is_reported();
  test_report_rejects_bad_arguments();

  printf("audio_medicion: %d comprobaciones, %d fallidas\n", g_run, g_failed);
  return g_failed == 0 ? 0 : 1;
}
