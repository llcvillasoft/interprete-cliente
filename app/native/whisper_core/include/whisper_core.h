/*
 * whisper_core: envoltura en C sobre whisper.cpp para la capa FFI de Dart (F2-07).
 *
 * Un modelo por instancia. Las muestras llegan a 16 kHz, mono, en coma flotante,
 * igual que exige el reconocedor. Los tiempos de los segmentos van en
 * centésimas de segundo, como los devuelve whisper.cpp.
 *
 * Hilos: wc_load, wc_free y wc_transcribe se llaman desde un solo hilo por modelo.
 */
#ifndef WHISPER_CORE_H
#define WHISPER_CORE_H

#include <stdint.h>

#if defined(_WIN32)
#  if defined(WHISPER_CORE_BUILD)
#    define WC_API __declspec(dllexport)
#  else
#    define WC_API __declspec(dllimport)
#  endif
#else
#  define WC_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct wc_model wc_model;
typedef struct wc_result wc_result;

typedef enum {
  WC_OK = 0,
  WC_ERR_ARG = -1,   /* argumento nulo, vacío o inválido */
  WC_ERR_MODEL = -2, /* el archivo del modelo no se pudo cargar */
  WC_ERR_RUN = -3    /* whisper.cpp no pudo transcribir */
} wc_status;

/* Carga el modelo desde `ruta_modelo`. `hilos` 0 usa 4 hilos. */
WC_API wc_status wc_load(const char *ruta_modelo, int32_t hilos, wc_model **out);
WC_API void wc_free(wc_model *modelo);

/* Transcribe `n` muestras a 16 kHz en el idioma `idioma` (p. ej. "es").
 * El resultado lo libera el llamador con wc_result_free. */
WC_API wc_status wc_transcribe(wc_model *modelo, const float *muestras, uint32_t n,
                               const char *idioma, wc_result **out);

WC_API int32_t wc_result_count(const wc_result *resultado);
WC_API int64_t wc_result_t0_cs(const wc_result *resultado, int32_t indice);
WC_API int64_t wc_result_t1_cs(const wc_result *resultado, int32_t indice);
/* Texto del segmento; válido hasta wc_result_free. NULL si el índice no existe. */
WC_API const char *wc_result_text(const wc_result *resultado, int32_t indice);
WC_API void wc_result_free(wc_result *resultado);

#ifdef __cplusplus
}
#endif

#endif /* WHISPER_CORE_H */
