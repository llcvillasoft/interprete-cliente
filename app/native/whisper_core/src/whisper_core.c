/*
 * Implementación pendiente de whisper_core (F2-07): versión provisional que
 * no carga ni transcribe, para que las pruebas queden en rojo.
 */
#include "whisper_core.h"

wc_status wc_load(const char *ruta_modelo, int32_t hilos, wc_model **out) {
  (void)ruta_modelo; (void)hilos; (void)out;
  return WC_ERR_ARG;
}

void wc_free(wc_model *modelo) { (void)modelo; }

wc_status wc_transcribe(wc_model *modelo, const float *muestras, uint32_t n,
                        const char *idioma, wc_result **out) {
  (void)modelo; (void)muestras; (void)n; (void)idioma; (void)out;
  return WC_ERR_ARG;
}

int32_t wc_result_count(const wc_result *resultado) { (void)resultado; return 0; }
int64_t wc_result_t0_cs(const wc_result *resultado, int32_t indice) { (void)resultado; (void)indice; return 0; }
int64_t wc_result_t1_cs(const wc_result *resultado, int32_t indice) { (void)resultado; (void)indice; return 0; }
const char *wc_result_text(const wc_result *resultado, int32_t indice) { (void)resultado; (void)indice; return NULL; }
void wc_result_free(wc_result *resultado) { (void)resultado; }
