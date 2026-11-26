/*
 * Arnés de medición del criterio 1 del POC (F2-02): error de 50 ms o menos con
 * audio sintético de instantes conocidos.
 *
 * Uso: medir_criterio1
 *
 * Requiere el bucle de retorno: la salida de la interfaz de audio conectada a
 * su entrada, con audífonos cableados (sin Bluetooth). Sin bucle de retorno, la
 * captura sale en silencio y el arnés termina con código 2.
 *
 * Programa 20 bloques de 0.5 s. Cada bloque lleva un clic al inicio y otro al
 * final, y entre bloques hay 0.1 s de silencio. El inicio de cada clic es un
 * instante conocido por construcción; el final de cada bloque es el T0 que
 * devuelve el motor, y su clic de cierre debe empezar CLIC muestras antes. Las
 * latencias de ida y vuelta se comparan con la mediana, y el error máximo se
 * compara con AM_UMBRAL_ERROR_MS.
 *
 * Código de salida: 0 si ambos grupos de instantes cumplen; 1 si alguno
 * supera el umbral; 2 si faltan o sobran clics, o el dispositivo falla.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "audio_core.h"
#include "audio_medicion.h"

#if defined(_WIN32)
#  include <windows.h>
static void sleep_ms(unsigned ms) { Sleep(ms); }
#else
#  include <time.h>
static void sleep_ms(unsigned ms) {
  struct timespec ts;
  ts.tv_sec = ms / 1000u;
  ts.tv_nsec = (long)(ms % 1000u) * 1000000L;
  nanosleep(&ts, NULL);
}
#endif

#define SR 48000u
#define BLOQUES 20u
#define LARGO_BLOQUE (SR / 2u)        /* 0.5 s */
#define SILENCIO (SR / 10u)           /* 0.1 s entre bloques */
#define CLIC 48u                      /* 1 ms a 48 kHz */
#define AMPLITUD 0.8f
#define UMBRAL_DETECCION 0.3f
#define REFRACTARIO (SR / 20u)        /* 50 ms: un clic cuenta una vez */
#define MAX_CLICS (2u * BLOQUES + 8u)

static void poner_clic(float *x, uint32_t desde) {
  uint32_t i;
  for (i = 0; i < CLIC; i++) x[desde + i] = AMPLITUD;
}

static int imprimir_informe(const char *nombre, const am_report *r) {
  printf("%s: %u pares, latencia %.2f ms, error máximo %.2f ms, error medio %.2f ms, %s\n",
         nombre, r->pairs, r->latency_ms, r->max_error_ms, r->mean_error_ms,
         r->pass ? "APTO" : "NO APTO");
  return r->pass;
}

int main(void) {
  static float bloque[LARGO_BLOQUE];
  static float silencio[SILENCIO];
  ac_config cfg;
  ac_engine *e = NULL;
  ac_status st;
  uint64_t tickets[BLOQUES];
  uint64_t ends[BLOQUES];
  uint64_t ticket_silencio = 0;
  uint64_t total_frames = (uint64_t)BLOQUES * (LARGO_BLOQUE + SILENCIO);
  uint64_t waited_ms = 0;
  float *captura;
  uint32_t capturados = 0;
  uint32_t capacidad = 14u * SR;
  uint32_t lidos;
  uint32_t onsets[MAX_CLICS];
  uint32_t n_onsets;
  uint64_t emit_ini[BLOQUES], det_ini[BLOQUES];
  uint64_t emit_fin[BLOQUES], det_fin[BLOQUES];
  am_report rep_ini, rep_fin;
  am_status ast;
  uint32_t i;
  int ok_ini, ok_fin;

  memset(&cfg, 0, sizeof cfg);
  cfg.sample_rate = SR;
  cfg.period_frames = 480;
  cfg.playback_capacity = (uint32_t)total_frames + SR;
  cfg.capture_capacity = capacidad;
  cfg.use_null_backend = 0;

  captura = (float *)malloc(capacidad * sizeof *captura);
  if (captura == NULL) {
    fprintf(stderr, "medir_criterio1: sin memoria para la captura\n");
    return 2;
  }

  if (ac_open(&cfg, &e) != AC_OK) {
    fprintf(stderr, "medir_criterio1: no se pudo abrir el flujo de audio\n");
    free(captura);
    return 2;
  }

  /* Bloques y silencios programados antes de arrancar: el reloj de reproducción
   * empieza en la muestra 0 con el primer bloque. */
  memset(bloque, 0, sizeof bloque);
  memset(silencio, 0, sizeof silencio);
  poner_clic(bloque, 0);
  poner_clic(bloque, LARGO_BLOQUE - CLIC);
  for (i = 0; i < BLOQUES; i++) {
    st = ac_schedule_playback(e, bloque, LARGO_BLOQUE, &tickets[i]);
    if (st != AC_OK) {
      fprintf(stderr, "medir_criterio1: bloque %u no programado (%d)\n", i, (int)st);
      ac_close(e);
      free(captura);
      return 2;
    }
    st = ac_schedule_playback(e, silencio, SILENCIO, &ticket_silencio);
    if (st != AC_OK) {
      fprintf(stderr, "medir_criterio1: silencio %u no programado (%d)\n", i, (int)st);
      ac_close(e);
      free(captura);
      return 2;
    }
  }

  if (ac_start(e) != AC_OK) {
    fprintf(stderr, "medir_criterio1: no arranca el dispositivo\n");
    ac_close(e);
    free(captura);
    return 2;
  }

  /* Espera a que pase toda la secuencia más medio segundo de cola. */
  while (ac_sample_counter(e) < total_frames + SR / 2u) {
    sleep_ms(100);
    waited_ms += 100;
    if (waited_ms > 60000u) {
      fprintf(stderr, "medir_criterio1: el reloj de audio no avanza\n");
      ac_close(e);
      free(captura);
      return 2;
    }
  }

  for (i = 0; i < BLOQUES; i++) {
    st = ac_playback_end_sample(e, tickets[i], &ends[i]);
    if (st != AC_OK) {
      fprintf(stderr, "medir_criterio1: T0 del bloque %u no disponible (%d)\n", i, (int)st);
      ac_close(e);
      free(captura);
      return 2;
    }
  }

  /* Captura completa desde el inicio del flujo. */
  do {
    lidos = ac_read_capture(e, captura + capturados, capacidad - capturados);
    capturados += lidos;
  } while (lidos > 0 && capturados < capacidad);
  ac_stop(e);
  ac_close(e);

  n_onsets = am_detect_onsets(captura, capturados, UMBRAL_DETECCION, REFRACTARIO,
                              onsets, MAX_CLICS);
  if (n_onsets != 2u * BLOQUES) {
    fprintf(stderr,
            "medir_criterio1: se detectaron %u clics y se esperaban %u; "
            "revisar el bucle de retorno y el nivel de salida\n",
            n_onsets, 2u * BLOQUES);
    free(captura);
    return 2;
  }

  /* Orden de detección: inicio, fin, inicio, fin… Cada inicio es i*(bloque+silencio);
   * cada fin, el T0 del bloque menos la duración del clic de cierre. */
  for (i = 0; i < BLOQUES; i++) {
    emit_ini[i] = (uint64_t)i * (LARGO_BLOQUE + SILENCIO);
    det_ini[i] = onsets[2 * i];
    emit_fin[i] = ends[i] - CLIC;
    det_fin[i] = onsets[2 * i + 1];
  }

  ast = am_latency_report(emit_ini, BLOQUES, det_ini, BLOQUES, SR, &rep_ini);
  if (ast != AM_OK) {
    fprintf(stderr, "medir_criterio1: informe de inicios no válido (%d)\n", (int)ast);
    free(captura);
    return 2;
  }
  ast = am_latency_report(emit_fin, BLOQUES, det_fin, BLOQUES, SR, &rep_fin);
  if (ast != AM_OK) {
    fprintf(stderr, "medir_criterio1: informe de finales no válido (%d)\n", (int)ast);
    free(captura);
    return 2;
  }

  ok_ini = imprimir_informe("inicio de rendición", &rep_ini);
  ok_fin = imprimir_informe("fin de rendición (T0)", &rep_fin);
  printf("criterio 1 (error <= %.0f ms): %s\n", AM_UMBRAL_ERROR_MS,
         ok_ini && ok_fin ? "CUMPLE" : "NO CUMPLE");

  free(captura);
  return ok_ini && ok_fin ? 0 : 1;
}
