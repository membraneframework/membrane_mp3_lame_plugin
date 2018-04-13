# Membrane.Element.Lame

Module containing element that encodes raw audio to MPEG-1 layer 3 format.

For now, only encoding audio with 2 channels, s32le format and 41000 sample rate is supported. 

## Compilation on Unix systems

To compile NIF you have to copy 'ext/lame.pc` to the repository visible by pkg-config (i.e. `/usr/lib/pkgconfig`)
