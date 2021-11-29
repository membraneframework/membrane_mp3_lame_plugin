#include "encoder.h"

static const int SAMPLE_SIZE = 4;
static const int SAMPLES_PER_FRAME = 1152;
// Magic numbers below taken from the worst case estimation in 'lame.h'
#if (defined(__GNUC__) && __GNUC__ >= 8) ||                                    \
    (defined(__clang__) && __clang_major__ >= 6)
static const int MAX_MP3_BUFFER_SIZE = 5 * SAMPLES_PER_FRAME / 4 + 7200;
#else
#define MAX_MP3_BUFFER_SIZE (5 * SAMPLES_PER_FRAME / 4 + 7200)
#endif

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  if (state->lame_state != NULL) {
    lame_close(state->lame_state);
  }
  if (state->mp3_buffer != NULL) {
    unifex_free(state->mp3_buffer);
  }
}

UNIFEX_TERM create(UnifexEnv *env, int channels, int bitrate, int quality) {
  UNIFEX_TERM result;
  State *state = unifex_alloc_state(env);
  state->lame_state = NULL;
  state->mp3_buffer = NULL;

  if (sizeof(int) != 4) {
    result = create_result_error(env, "invalid_int_size");
    goto create_exit;
  }

  state->lame_state = lame_init();
  lame_global_flags *lame_state = state->lame_state;

  lame_set_num_channels(lame_state, channels);
  lame_set_in_samplerate(lame_state, 44100);
  lame_set_brate(lame_state, bitrate);
  lame_set_quality(lame_state, quality);

  if (lame_init_params(lame_state) < 0) {
    result = create_result_error(env, "lame_init");
    goto create_exit;
  }

  state->mp3_buffer = unifex_alloc(MAX_MP3_BUFFER_SIZE);
  state->channels = channels;

  result = create_result_ok(env, state);
create_exit:
  unifex_release_state(env, state);
  return result;
}

UNIFEX_TERM encode_frame(UnifexEnv *env, UnifexPayload *buffer, State *state) {
  int num_of_samples = buffer->size / (state->channels * SAMPLE_SIZE);

  int *samples = (int *)buffer->data;
  int *left_samples = unifex_alloc(num_of_samples * SAMPLE_SIZE);
  int *right_samples = unifex_alloc(num_of_samples * SAMPLE_SIZE);

  for (int i = 0; i < num_of_samples; i++) {
    left_samples[i] = samples[i * 2];
    right_samples[i] = samples[i * 2 + 1];
  }

  // Encode the buffer
  int result = lame_encode_buffer_int(state->lame_state, left_samples,
                                      right_samples, num_of_samples,
                                      state->mp3_buffer, MAX_MP3_BUFFER_SIZE);

  unifex_free(left_samples);
  unifex_free(right_samples);

  switch (result) {
  case MP3_BUFFER_TOO_SMALL:
    return encode_frame_result_error(env, "buflen");
    break;

  case MALLOC_PROBLEM:
    return encode_frame_result_error(env, "malloc");
    break;

  case LAME_INIT_PARAMS_NOT_CALLED:
    return encode_frame_result_error(env, "lame_no_init");
    break;

  case PSYCHO_ACOUSTIC_PROBLEMS:
    return encode_frame_result_error(env, "lame_acoustic");
    break;

  default:
    // No error - result contains number of bytes in output buffer.
    break;
  }

  UnifexPayload *output_payload = (UnifexPayload *)unifex_alloc(sizeof(UnifexPayload));
  unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, result, output_payload);
  memcpy(output_payload->data, state->mp3_buffer, result);

  UNIFEX_TERM res_term = encode_frame_result_ok(env, output_payload);
  unifex_payload_release(output_payload);
  unifex_free(output_payload);
  return res_term;
}

UNIFEX_TERM flush(UnifexEnv *env, int is_gapless, State *state) {
  int output_size;
  if (is_gapless) {
    output_size = lame_encode_flush_nogap(state->lame_state, state->mp3_buffer,
                                          MAX_MP3_BUFFER_SIZE);
  } else {
    output_size = lame_encode_flush(state->lame_state, state->mp3_buffer,
                                    MAX_MP3_BUFFER_SIZE);
  }
  UnifexPayload *output_payload = (UnifexPayload *)unifex_alloc(sizeof(UnifexPayload));
  unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, output_size, output_payload);
  
  memcpy(output_payload->data, state->mp3_buffer, output_size);

  UNIFEX_TERM res_term = flush_result_ok(env, output_payload);
  unifex_payload_release(output_payload);
  unifex_free(output_payload);
  return res_term;
}
