defmodule Membrane.Element.Lame.EncoderOptions do
  defstruct \
    channels: nil

  @type t :: %Membrane.Element.Lame.EncoderOptions{
    channels: integer
  }
end
