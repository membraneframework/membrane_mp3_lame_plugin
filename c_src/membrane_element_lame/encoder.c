#include "encoder.h"

ErlNifResourceType *RES_ENCODER_HANDLE_TYPE;
const int SAMPLE_SIZE = 4;
const int SAMPLES_PER_FRAME = 1152;

void handle_destroy_state(UnifexEnv *env, UnifexNifState *state) {
  UNIFEX_UNUSED(env);
  MEMBRANE_DEBUG(env, "Destroying EncoderHandle %p", state);

  if (state->gfp != NULL) {
    lame_close(state->gfp);
  }
  if (state->mp3buffer != NULL) {
    unifex_free(state->mp3buffer);
  }
}

UNIFEX_TERM create(UnifexEnv *env, int channels, int bitrate, int quality) {
  UNIFEX_TERM result;
  State *state = unifex_alloc_state(env);
  state->gfp = NULL;
  state->mp3buffer = NULL;

  if (sizeof(int) != 4) {
    result = create_result_error(env, "invalid_int_size");
    goto create_exit;
  }

  state->gfp = lame_init();
  lame_global_flags *gfp = state->gfp;

  lame_set_num_channels(gfp, channels);
  lame_set_in_samplerate(gfp, 44100);
  lame_set_brate(gfp, bitrate);
  lame_set_quality(gfp, quality); /* 2=high  5 = medium  7=low */

  if (lame_init_params(gfp) < 0) {
    result = create_result_error(env, "lame_init");
    goto create_exit;
  }

  state->max_mp3buffer_size = 5 * SAMPLES_PER_FRAME / 4 + 7200;
  state->gfp = gfp;
  state->mp3buffer = unifex_alloc(state->max_mp3buffer_size);
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
  int result = lame_encode_buffer_int(state->gfp, left_samples, right_samples,
                                      num_of_samples, state->mp3buffer,
                                      state->max_mp3buffer_size);

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

  UnifexPayload *output_payload =
      unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, result);
  memcpy(output_payload->data, state->mp3buffer, result);

  UNIFEX_TERM res_term = encode_frame_result_ok(env, output_payload);
  unifex_payload_release(output_payload);
  return res_term;
}

UNIFEX_TERM flush(UnifexEnv *env, State *state) {
  int output_size = lame_encode_flush(state->gfp, state->mp3buffer,
                                      state->max_mp3buffer_size);
  UnifexPayload *output_payload =
      unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, output_size);
  memcpy(output_payload->data, state->mp3buffer, output_size);

  UNIFEX_TERM res_term = flush_result_ok(env, output_payload);
  unifex_payload_release(output_payload);
  return res_term;
}
