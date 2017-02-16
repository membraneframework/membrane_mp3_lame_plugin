/**
 * Membrane Element: Lame Encoder - Erlang native interface to native
 * lame encoder.
 *
 * All Rights Reserved, (c) 2016 Filip Abramowicz
 */

#include "encoder.h"
#include <string.h>
#include <membrane/membrane.h>



ErlNifResourceType *RES_ENCODER_HANDLE_TYPE;


void res_encoder_handle_destructor(ErlNifEnv *env, void *value) {
  EncoderHandle *handle = (EncoderHandle *) value;
  MEMBRANE_DEBUG("Destroying EncoderHandle %p", handle);

  enif_release_resource(handle);
}


int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
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
  EncoderHandle *handle;
  lame_global_flags *gfp;

  // TODO - argument validation

  gfp = lame_init();

  lame_set_num_channels(gfp, 2);
  lame_set_in_samplerate(gfp, 44100);
  lame_set_brate(gfp, 128);
  lame_set_mode(gfp, 1);
  lame_set_quality(gfp, 2);   /* 2=high  5 = medium  7=low */

  int error = lame_init_params(gfp);
  if (error)
  {
    return membrane_util_make_error_internal(env, "failedtoinitializelame");
  }

  // Initialize handle
  handle = enif_alloc_resource(RES_ENCODER_HANDLE_TYPE, sizeof(EncoderHandle));

  MEMBRANE_DEBUG("Initialized EncoderHandle %p", handle);

  handle->gfp = gfp;

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
static ERL_NIF_TERM export_encode_buffer(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  EncoderHandle*        handle;
  ErlNifBinary          left_buffer;
  ErlNifBinary          right_buffer;
  int                   num_of_samples;

  // Get resource arg
  if(!enif_get_resource(env, argv[0], RES_ENCODER_HANDLE_TYPE, (void **) &handle)) {
    return membrane_util_make_error_args(env, "data", "Given encoder is not valid resource");
  }

  // Get data arg
  if(!enif_inspect_binary(env, argv[1], &left_buffer)) {
    return membrane_util_make_error_args(env, "data", "Given data for left channel is not valid binary");
  }
  if(!enif_inspect_binary(env, argv[2], &right_buffer)) {
    return membrane_util_make_error_args(env, "data", "Given data for right channel is not valid binary");
  }

  if(!enif_get_int(env, argv[3], &num_of_samples)) {
    return membrane_util_make_error_args(env, "data", "Given data for number of samples is not valid");
  }

  // This is worst case calculation, should be changed to more precise one
  int mp3buffer_size = 1.25 * num_of_samples + 7200;

  // Prepare data for returned terms
  ERL_NIF_TERM output_data;
  handle->mp3buffer = enif_make_new_binary(env, mp3buffer_size, &output_data);

  // Encode the buffer
  int result = lame_encode_buffer(handle->gfp, (const short int*)&left_buffer, (const short int*)&right_buffer,
                                  num_of_samples, handle->mp3buffer, mp3buffer_size);

  if(result < 0)
  {
    return membrane_util_make_error_args(env, "encoder", "Lame unable to encode provided data");
  }

  return membrane_util_make_ok_tuple(env, output_data);
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
  EncoderHandle* handle;

  // Get resource arg
  if(!enif_get_resource(env, argv[0], RES_ENCODER_HANDLE_TYPE, (void **) &handle)) {
    return membrane_util_make_error_args(env, "encoder", "Given encoder is not valid resource");
  }

  lame_close(handle->gfp);

  // Return value
  return membrane_util_make_ok(env);
}


static ErlNifFunc nif_funcs[] =
{
  {"create", 0, export_create},
  {"encode_buffer", 4, export_encode_buffer},
  {"destroy", 1, export_destroy}
};

ERL_NIF_INIT(Elixir.Membrane.Element.Lame.EncoderNative, nif_funcs, load, NULL, NULL, NULL)
