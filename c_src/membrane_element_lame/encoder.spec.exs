module Membrane.Element.Lame.Encoder.Native

spec create(channels :: int, bitrate :: int, quality :: int) ::
       {:ok :: label, state} | {:error :: label, reason :: atom}

spec encode_frame(buffer :: payload, state) :: {:ok :: label, frame :: payload} | {:error :: label, reason :: atom}
