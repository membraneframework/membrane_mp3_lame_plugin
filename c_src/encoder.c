/**
 * Membrane Element: Lame Encoder - Erlang native interface to native
 * lame encoder.
 *
 * All Rights Reserved, (c) 2016 Filip Abramowicz
 */

#include "encoder.h"
#include <string.h>
#include <membrane/membrane.h>


#define MP3_BUFFER_TOO_SMALL        -1
#define MALLOC_PROBLEM              -2
#define LAME_INIT_PARAMS_NOT_CALLED -3
#define PSYCHO_ACOUSTIC_PROBLEMS    -4
#define UNUSED(x) (void)(x)

ErlNifResourceType *RES_ENCODER_HANDLE_TYPE;
const int SAMPLE_SIZE = 4;
const int SAMPLES_PER_FRAME = 1152;


void res_encoder_handle_destructor(ErlNifEnv *env, void *value) {
  UNUSED(env);
  EncoderHandle *handle = (EncoderHandle *) value;
  MEMBRANE_DEBUG("Destroying EncoderHandle %p", handle);

  if (handle->mp3buffer != NULL)
  {
    free(handle->mp3buffer);
  }

  enif_release_resource(handle);
}


int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  UNUSED(priv_data);
  UNUSED(load_info);
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_ENCODER_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "EncoderHandle", res_encoder_handle_destructor, flags, NULL);
  return 0;
}


/**
 *
 * Creates encoder.
 *
 * It accepts one argument:
 *
 * - format - atom representing raw sample format,
 *
 * On success, returns `{:ok, resource}`.
 *
 * On bad arguments passed, returns `{:error, {:args, field, description}}`.
 *
 * On aggregator initialization error, returns `{:error, {:internal, reason}}`.
 */
static ERL_NIF_TERM export_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  UNUSED(argc);
  UNUSED(argv);
  EncoderHandle *handle;
  int bitrate = 0;
  int channels = 0;
  int quality = 0;
  lame_global_flags *gfp;
 
  if(!enif_get_int(env, argv[0], &channels)) {
    return membrane_util_make_error_args(env, "args", "Invalid number of channels");
  }
  if(!enif_get_int(env, argv[1], &bitrate)) {
    return membrane_util_make_error_args(env, "args", "Invalid bitrate value");
  }
  if(!enif_get_int(env, argv[2], &quality)) {
    return membrane_util_make_error_args(env, "args", "Invalid quality");
  }
  if(sizeof(int) != 4) {
    return membrane_util_make_error(env, enif_make_string(env, "invalid int size", ERL_NIF_LATIN1));
  }


  // TODO - argument validation

  gfp = lame_init();

  lame_set_num_channels(gfp, channels);
  lame_set_in_samplerate(gfp, 44100);
  lame_set_brate(gfp, bitrate);
  lame_set_quality(gfp, quality);   /* 2=high  5 = medium  7=low */

  int error = lame_init_params(gfp);
  if (error)
  {
    return membrane_util_make_error_internal(env, "failedtoinitializelame");
  }

  // Initialize handle
  handle = enif_alloc_resource(RES_ENCODER_HANDLE_TYPE, sizeof(EncoderHandle));

  MEMBRANE_DEBUG("Initialized EncoderHandle %p", handle);


  handle->max_mp3buffer_size = 1.25 * SAMPLES_PER_FRAME + 7200;
  handle->gfp = gfp;
  handle->mp3buffer = malloc(handle->max_mp3buffer_size);
  handle->channels = channels;

  // Prepare return term
  ERL_NIF_TERM encoder_term = enif_make_resource(env, handle);
  enif_release_resource(handle);

  return membrane_util_make_ok_tuple(env, encoder_term);
}


/**
 * Encodes buffer.
 *
 * It accepts two arguments:
 *
 * - resource - aggregator resource,
 * - data - buffer to encode
 *
 * On success, returns `{:ok, data}` where data always contain one sample in
 * the same format and channels as given to `create/3`.
 *
 * On bad arguments passed, returns `{:error, {:args, field, description}}`.
 *
 * On internal error, returns `{:error, {:internal, reason}}`.
 */
static ERL_NIF_TERM export_encode_frame(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  UNUSED(argc);
  EncoderHandle*        handle;
  ErlNifBinary          buffer;

  // Get resource arg
  if(!enif_get_resource(env, argv[0], RES_ENCODER_HANDLE_TYPE, (void **) &handle)) {
    return membrane_util_make_error_args(env, "data", "Given encoder is not valid resource");
  }

  // Get data arg
  if(!enif_inspect_binary(env, argv[1], &buffer)) {
    return membrane_util_make_error_args(env, "data", "Given data for left channel is not valid binary");
  }

  // This is worst case calculation, should be changed to more precise one
  int num_of_samples = buffer.size / (handle->channels * SAMPLE_SIZE); 
  if (num_of_samples < SAMPLES_PER_FRAME){
    return membrane_util_make_error(env, enif_make_atom(env ,"buflen"));
  }
  
  int *samples = (int*) buffer.data;
  int *left_samples = malloc(num_of_samples * sizeof(int));
  int *right_samples = malloc(num_of_samples * sizeof(int));


  for (int i = 0; i < num_of_samples; i++) {
    left_samples[i] = samples[i*2];
    right_samples[i] = samples[i*2+1];
  }

  // Encode the buffer
  int result = lame_encode_buffer_int(handle->gfp,
                                  left_samples,
                                  right_samples,
                                  num_of_samples,
                                  handle->mp3buffer,
                                  handle->max_mp3buffer_size);

  switch (result)
  {
    case MP3_BUFFER_TOO_SMALL:
      return membrane_util_make_error_args(env, "encoder", "MP3 buffer was too small");
      break;

    case MALLOC_PROBLEM:
      return membrane_util_make_error_args(env, "encoder", "There was malloc problem in lame");
      break;

    case LAME_INIT_PARAMS_NOT_CALLED:
      return membrane_util_make_error_args(env, "encoder", "Lame_init_params not called");
      break;

    case PSYCHO_ACOUSTIC_PROBLEMS:
      return membrane_util_make_error_args(env, "encoder", "Psycho acoustic problems in lame");
      break;

    default:
      // No error - result contains number of bytes in output buffer.
      break;
  }

  ERL_NIF_TERM encoded_frame;

  // Move encoded data to fit buffer
  unsigned char* outputbuffer = enif_make_new_binary(env, result, &encoded_frame);
  memcpy(outputbuffer, handle->mp3buffer, result);

  return membrane_util_make_ok_tuple(env, encoded_frame);
}


/**
 * Destroys the encoder.
 *
 * It accepts one argument:
 *
 * - resource - aggregator resource.
 *
 * On success, returns `:ok`.
 *
 * On bad arguments passed, returns `{:error, {:args, field, description}}`.
 */
static ERL_NIF_TERM export_destroy(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  UNUSED(argc);
  EncoderHandle* handle;

  // Get resource arg
  if(!enif_get_resource(env, argv[0], RES_ENCODER_HANDLE_TYPE, (void **) &handle)) {
    return membrane_util_make_error_args(env, "encoder", "Given encoder is not valid resource");
  }

  lame_close(handle->gfp);

  if (handle->mp3buffer != NULL)
  {
    free(handle->mp3buffer);
  }

  // Return value
  return membrane_util_make_ok(env);
}


static ErlNifFunc nif_funcs[] =
{
  {"create", 3, export_create, 0},
  {"encode_frame", 2, export_encode_frame, 0},
  {"destroy", 1, export_destroy, 0}
};

ERL_NIF_INIT(Elixir.Membrane.Element.Lame.EncoderNative, nif_funcs, load, NULL, NULL, NULL)
