/*
 * Pruebas de whisper_core (F2-07). Las de argumentos y de carga no necesitan
 * modelo. La de transcripción real se omite si no se define WHISPER_MODELO_PRUEBA
 * con la ruta de un modelo ggml (p. ej. tiny).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "whisper_core.h"

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

static void test_load_rejects_bad_arguments(void) {
  wc_model *m = NULL;
  CHECK(wc_load(NULL, 4, &m) == WC_ERR_ARG);
  CHECK(wc_load("/ruta/inexistente.bin", 4, NULL) == WC_ERR_ARG);
  CHECK(m == NULL);
}

static void test_load_reports_missing_model(void) {
  wc_model *m = (wc_model *)1;
  CHECK(wc_load("/ruta/que/no/existe/ggml-tiny.bin", 0, &m) == WC_ERR_MODEL);
  CHECK(m == NULL);
}

static void test_transcribe_rejects_bad_arguments(void) {
  float muestras[16] = {0};
  wc_result *r = NULL;
  CHECK(wc_transcribe(NULL, muestras, 16, "es", &r) == WC_ERR_ARG);
  CHECK(wc_transcribe(NULL, NULL, 16, "es", &r) == WC_ERR_ARG);
  CHECK(wc_transcribe(NULL, muestras, 0, "es", &r) == WC_ERR_ARG);
  CHECK(wc_transcribe(NULL, muestras, 16, NULL, &r) == WC_ERR_ARG);
  CHECK(wc_transcribe(NULL, muestras, 16, "es", NULL) == WC_ERR_ARG);
  CHECK(r == NULL);
}

static void test_null_handles_are_safe(void) {
  wc_free(NULL);
  wc_result_free(NULL);
  CHECK(wc_result_count(NULL) == 0);
  CHECK(wc_result_t0_cs(NULL, 0) == 0);
  CHECK(wc_result_t1_cs(NULL, 0) == 0);
  CHECK(wc_result_text(NULL, 0) == NULL);
}

static void test_real_transcription_when_model_is_provided(void) {
  const char *ruta = getenv("WHISPER_MODELO_PRUEBA");
  wc_model *m = NULL;
  wc_result *r = NULL;
  float silencio[16000];
  if (ruta == NULL || ruta[0] == '\0') {
    printf("transcripción real omitida: falta WHISPER_MODELO_PRUEBA\n");
    return;
  }
  memset(silencio, 0, sizeof silencio);
  CHECK(wc_load(ruta, 0, &m) == WC_OK);
  if (m == NULL) return;
  CHECK(wc_transcribe(m, silencio, 16000, "es", &r) == WC_OK);
  CHECK(r != NULL);
  if (r != NULL) {
    CHECK(wc_result_count(r) >= 0);
    CHECK(wc_result_text(r, 1000000) == NULL);
    wc_result_free(r);
  }
  wc_free(m);
}

int main(void) {
  test_load_rejects_bad_arguments();
  test_load_reports_missing_model();
  test_transcribe_rejects_bad_arguments();
  test_null_handles_are_safe();
  test_real_transcription_when_model_is_provided();

  printf("whisper_core: %d comprobaciones, %d fallidas\n", g_run, g_failed);
  return g_failed == 0 ? 0 : 1;
}
