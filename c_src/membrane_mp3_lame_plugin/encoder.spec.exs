module Membrane.MP3.Lame.Encoder.Native

spec create(channels :: int, bitrate :: int, quality :: int) ::
       {:ok :: label, state} | {:error :: label, reason :: atom}

spec encode_frame(buffer :: payload, state) ::
       {:ok :: label, frame :: payload} | {:error :: label, reason :: atom}

spec flush(is_gapless :: bool, state) ::
       {:ok :: label, frame :: payload} | {:error :: label, reason :: atom}

state_type "State"

dirty :cpu, encode_frame: 2, flush: 2
