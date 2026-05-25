module Membrane.MP3.Lame.Encoder.Native

type rate_control :: %Membrane.MP3.Lame.Encoder.RateControl{
       type: int,
       bitrate: int,
       quality: float,
       mean_bitrate: int,
       min_bitrate: int,
       max_bitrate: int,
       hard_min: bool
     }

spec create(
       channels :: int,
       quality :: int,
       disable_reservoir :: bool,
       rate_control :: rate_control
     ) ::
       {:ok :: label, state} | {:error :: label, reason :: atom}

spec encode_frame(buffer :: payload, state) ::
       {:ok :: label, frame :: payload} | {:error :: label, reason :: atom}

spec flush(is_gapless :: bool, state) ::
       {:ok :: label, frame :: payload} | {:error :: label, reason :: atom}

state_type "State"

dirty :cpu, encode_frame: 2, flush: 2
