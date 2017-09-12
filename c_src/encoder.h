/**
 * Membrane Element: Lame Encoder - Erlang native interface to native
 * lame encoder.
 *
 * All Rights Reserved, (c) 2016 Filip Abramowicz
 */

#ifndef __ENCODER_H__
#define __ENCODER_H__

#define MEMBRANE_LOG_TAG "Membrane.Element.Lame.Encoder"


#include <stdio.h>
#include <erl_nif.h>
#include <lame/lame.h>

typedef struct _EncoderHandle EncoderHandle;

struct _EncoderHandle
{
    lame_global_flags* gfp;
    char*              mp3buffer;
};

#endif
