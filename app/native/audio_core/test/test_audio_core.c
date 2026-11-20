/*
 * Pruebas del núcleo de audio (F2-02) con el backend nulo de miniaudio.
 * El backend nulo corre en tiempo real sin tarjeta de sonido, así que estas
 * pruebas no sustituyen la medición de latencia en un equipo Windows real.
 */
#include <stdio.h>
#include <string.h>

#include "audio_core.h"

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

static ac_config null_config(uint32_t playback_frames, uint32_t capture_frames) {
  ac_config c;
  memset(&c, 0, sizeof c);
  c.sample_rate = 48000;
  c.period_frames = 480;
  c.playback_capacity = playback_frames;
  c.capture_capacity = capture_frames;
  c.use_null_backend = 1;
  return c;
}

static void test_open_rejects_null_out(void) {
  ac_config c = null_config(48000, 48000);
  CHECK(ac_open(&c, NULL) == AC_ERR_ARG);
}

static void test_open_reports_requested_format(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;
  ac_info info;
  memset(&info, 0, sizeof info);

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_get_info(e, &info) == AC_OK);
  CHECK(info.sample_rate == 48000);
  CHECK(info.channels == 1);
  CHECK(info.input_latency_frames > 0);
  CHECK(info.output_latency_frames > 0);
  ac_close(e);
}

static void test_counter_advances_only_while_running(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;
  uint64_t running_count, stopped_count;

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_sample_counter(e) == 0);
  CHECK(ac_start(e) == AC_OK);
  sleep_ms(200);
  running_count = ac_sample_counter(e);
  CHECK(running_count > 0);
  CHECK(ac_stop(e) == AC_OK);
  stopped_count = ac_sample_counter(e);
  sleep_ms(150);
  CHECK(ac_sample_counter(e) == stopped_count);
  ac_close(e);
}

static void test_start_twice_and_stop_before_start_are_state_errors(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_stop(e) == AC_ERR_STATE);
  CHECK(ac_start(e) == AC_OK);
  CHECK(ac_start(e) == AC_ERR_STATE);
  CHECK(ac_stop(e) == AC_OK);
  ac_close(e);
}

static void test_playback_accepts_up_to_capacity(void) {
  ac_config c = null_config(1000, 1000);
  ac_engine *e = NULL;
  float buf[800];
  memset(buf, 0, sizeof buf);

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_write_playback(e, buf, 800) == 800);
  CHECK(ac_write_playback(e, buf, 800) == 200);
  CHECK(ac_playback_pending(e) == 1000);
  CHECK(ac_write_playback(e, buf, 1) == 0);
  ac_close(e);
}

static void test_playback_drains_while_running(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;
  float buf[4800];
  memset(buf, 0, sizeof buf);

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_write_playback(e, buf, 4800) == 4800);
  CHECK(ac_start(e) == AC_OK);
  sleep_ms(300);
  CHECK(ac_playback_pending(e) == 0);
  CHECK(ac_stop(e) == AC_OK);
  ac_close(e);
}

static void test_underruns_count_when_playback_is_empty(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_start(e) == AC_OK);
  sleep_ms(200);
  CHECK(ac_playback_underrun_frames(e) > 0);
  CHECK(ac_stop(e) == AC_OK);
  ac_close(e);
}

static void test_capture_delivers_frames_while_running(void) {
  ac_config c = null_config(48000, 48000);
  ac_engine *e = NULL;
  float buf[4800];

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_start(e) == AC_OK);
  sleep_ms(300);
  CHECK(ac_read_capture(e, buf, 4800) > 0);
  CHECK(ac_stop(e) == AC_OK);
  ac_close(e);
}

static void test_capture_counts_overruns_when_not_read(void) {
  ac_config c = null_config(48000, 960);
  ac_engine *e = NULL;

  CHECK(ac_open(&c, &e) == AC_OK);
  if (!e) return;
  CHECK(ac_start(e) == AC_OK);
  sleep_ms(300);
  CHECK(ac_capture_overrun_frames(e) > 0);
  CHECK(ac_stop(e) == AC_OK);
  ac_close(e);
}

static void test_null_arguments_are_safe(void) {
  float buf[4];
  CHECK(ac_start(NULL) == AC_ERR_ARG);
  CHECK(ac_stop(NULL) == AC_ERR_ARG);
  ac_close(NULL);
  CHECK(ac_sample_counter(NULL) == 0);
  CHECK(ac_write_playback(NULL, buf, 4) == 0);
  CHECK(ac_playback_pending(NULL) == 0);
  CHECK(ac_read_capture(NULL, buf, 4) == 0);
  CHECK(ac_playback_underrun_frames(NULL) == 0);
  CHECK(ac_capture_overrun_frames(NULL) == 0);
}

int main(void) {
  test_open_rejects_null_out();
  test_open_reports_requested_format();
  test_counter_advances_only_while_running();
  test_start_twice_and_stop_before_start_are_state_errors();
  test_playback_accepts_up_to_capacity();
  test_playback_drains_while_running();
  test_underruns_count_when_playback_is_empty();
  test_capture_delivers_frames_while_running();
  test_capture_counts_overruns_when_not_read();
  test_null_arguments_are_safe();

  printf("audio_core: %d comprobaciones, %d fallidas\n", g_run, g_failed);
  return g_failed == 0 ? 0 : 1;
}
