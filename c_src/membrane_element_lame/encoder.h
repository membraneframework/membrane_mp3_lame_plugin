#pragma once

#define MEMBRANE_LOG_TAG "Membrane.Element.Lame.Encoder"

#include <lame/lame.h>
#include <membrane/log.h>
#include <membrane/membrane.h>
#include <string.h>

typedef struct _EncoderState {
  lame_global_flags *lame_state;
  unsigned char *mp3buffer;
  int channels;
  int max_mp3buffer_size;
} UnifexNifState;

typedef UnifexNifState State;

#include "_generated/encoder.h"

#define MP3_BUFFER_TOO_SMALL (-1)
#define MALLOC_PROBLEM (-2)
#define LAME_INIT_PARAMS_NOT_CALLED (-3)
#define PSYCHO_ACOUSTIC_PROBLEMS (-4)
