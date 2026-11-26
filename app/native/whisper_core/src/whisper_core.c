/*
 * Implementación de whisper_core (F2-07) sobre whisper.cpp.
 */
#include "whisper_core.h"

#include <stdlib.h>
#include <string.h>

#include "whisper.h"

#define HILOS_POR_OMISION 4

struct wc_model {
  struct whisper_context *ctx;
  int32_t hilos;
};

static char *copiar_texto(const char *fuente) {
  size_t n = strlen(fuente);
  char *copia = (char *)malloc(n + 1);
  if (copia != NULL) memcpy(copia, fuente, n + 1);
  return copia;
}

struct wc_result {
  int32_t count;
  int64_t *t0;
  int64_t *t1;
  char **texto;
};

wc_status wc_load(const char *ruta_modelo, int32_t hilos, wc_model **out) {
  struct whisper_context_params cparams;
  struct whisper_context *ctx;
  wc_model *m;

  if (ruta_modelo == NULL || ruta_modelo[0] == '\0' || out == NULL) return WC_ERR_ARG;
  if (hilos < 0) return WC_ERR_ARG;
  *out = NULL;

  cparams = whisper_context_default_params();
  cparams.use_gpu = false; /* determinista en CI y en equipos sin GPU compatible */
  ctx = whisper_init_from_file_with_params(ruta_modelo, cparams);
  if (ctx == NULL) return WC_ERR_MODEL;

  m = (wc_model *)calloc(1, sizeof *m);
  if (m == NULL) {
    whisper_free(ctx);
    return WC_ERR_MODEL;
  }
  m->ctx = ctx;
  m->hilos = hilos > 0 ? hilos : HILOS_POR_OMISION;
  *out = m;
  return WC_OK;
}

void wc_free(wc_model *modelo) {
  if (modelo == NULL) return;
  if (modelo->ctx != NULL) whisper_free(modelo->ctx);
  free(modelo);
}

wc_status wc_transcribe(wc_model *modelo, const float *muestras, uint32_t n,
                        const char *idioma, wc_result **out) {
  struct whisper_full_params params;
  wc_result *r;
  int i;
  int segmentos;

  if (modelo == NULL || modelo->ctx == NULL || muestras == NULL || n == 0 ||
      idioma == NULL || idioma[0] == '\0' || out == NULL) {
    return WC_ERR_ARG;
  }
  *out = NULL;

  params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  params.language = idioma;
  params.n_threads = modelo->hilos;
  params.print_progress = false;
  params.print_realtime = false;
  params.print_timestamps = false;

  if (whisper_full(modelo->ctx, params, muestras, (int)n) != 0) return WC_ERR_RUN;

  segmentos = whisper_full_n_segments(modelo->ctx);
  if (segmentos < 0) return WC_ERR_RUN;

  r = (wc_result *)calloc(1, sizeof *r);
  if (r == NULL) return WC_ERR_RUN;
  if (segmentos > 0) {
    r->t0 = (int64_t *)calloc((size_t)segmentos, sizeof *r->t0);
    r->t1 = (int64_t *)calloc((size_t)segmentos, sizeof *r->t1);
    r->texto = (char **)calloc((size_t)segmentos, sizeof *r->texto);
    if (r->t0 == NULL || r->t1 == NULL || r->texto == NULL) {
      wc_result_free(r);
      return WC_ERR_RUN;
    }
  }
  r->count = segmentos;

  for (i = 0; i < segmentos; i++) {
    const char *fuente = whisper_full_get_segment_text(modelo->ctx, i);
    r->t0[i] = whisper_full_get_segment_t0(modelo->ctx, i);
    r->t1[i] = whisper_full_get_segment_t1(modelo->ctx, i);
    r->texto[i] = copiar_texto(fuente != NULL ? fuente : "");
    if (r->texto[i] == NULL) {
      wc_result_free(r);
      return WC_ERR_RUN;
    }
  }

  *out = r;
  return WC_OK;
}

int32_t wc_result_count(const wc_result *resultado) {
  return resultado == NULL ? 0 : resultado->count;
}

int64_t wc_result_t0_cs(const wc_result *resultado, int32_t indice) {
  if (resultado == NULL || indice < 0 || indice >= resultado->count) return 0;
  return resultado->t0[indice];
}

int64_t wc_result_t1_cs(const wc_result *resultado, int32_t indice) {
  if (resultado == NULL || indice < 0 || indice >= resultado->count) return 0;
  return resultado->t1[indice];
}

const char *wc_result_text(const wc_result *resultado, int32_t indice) {
  if (resultado == NULL || indice < 0 || indice >= resultado->count) return NULL;
  return resultado->texto[indice];
}

void wc_result_free(wc_result *resultado) {
  int32_t i;
  if (resultado == NULL) return;
  if (resultado->texto != NULL) {
    for (i = 0; i < resultado->count; i++) free(resultado->texto[i]);
    free(resultado->texto);
  }
  free(resultado->t0);
  free(resultado->t1);
  free(resultado);
}
