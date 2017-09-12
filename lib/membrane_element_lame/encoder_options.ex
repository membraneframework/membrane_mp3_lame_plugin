defmodule Membrane.Element.Lame.Encoder.Options do
  defstruct \
    channels: nil

  @type t :: %Membrane.Element.Lame.Encoder.Options{
    channels: integer
  }
end
