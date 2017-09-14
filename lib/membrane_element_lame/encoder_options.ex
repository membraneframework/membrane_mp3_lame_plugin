defmodule Membrane.Element.Lame.Encoder.Options do
  defstruct \
    channels: 2,
    bitrate: 192, 
    quality: :medium

  @type t :: %Membrane.Element.Lame.Encoder.Options{
    channels: integer,
    bitrate: integer,
    quality: :low | :medium | :high | integer
  }

  @doc false
  @spec map_quality_to_value(atom) :: pos_integer
  def map_quality_to_value(:low), do: 7
  def map_quality_to_value(:medium), do: 5
  def map_quality_to_value(:high), do: 2
  def map_quality_to_value(quality) when is_integer(quality) and quality >= 0 and quality <= 9, do: quality
  def map_quality_to_value(_), do: 5

end
