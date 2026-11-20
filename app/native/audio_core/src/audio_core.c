/* Stub en rojo: las pruebas deben fallar por aserción hasta implementar. */
#include "audio_core.h"

ac_status ac_open(const ac_config *config, ac_engine **out) { (void)config; (void)out; return AC_ERR_INIT; }
ac_status ac_start(ac_engine *engine) { (void)engine; return AC_ERR_ARG; }
ac_status ac_stop(ac_engine *engine) { (void)engine; return AC_ERR_ARG; }
void ac_close(ac_engine *engine) { (void)engine; }
ac_status ac_get_info(const ac_engine *engine, ac_info *out) { (void)engine; (void)out; return AC_ERR_ARG; }
uint64_t ac_sample_counter(const ac_engine *engine) { (void)engine; return 0; }
uint32_t ac_write_playback(ac_engine *engine, const float *samples, uint32_t frames) { (void)engine; (void)samples; (void)frames; return 0; }
uint32_t ac_playback_pending(const ac_engine *engine) { (void)engine; return 0; }
uint32_t ac_read_capture(ac_engine *engine, float *dst, uint32_t max_frames) { (void)engine; (void)dst; (void)max_frames; return 0; }
uint64_t ac_playback_underrun_frames(const ac_engine *engine) { (void)engine; return 0; }
uint64_t ac_capture_overrun_frames(const ac_engine *engine) { (void)engine; return 0; }
