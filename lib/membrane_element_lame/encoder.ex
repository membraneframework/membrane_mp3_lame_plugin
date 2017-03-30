defmodule Membrane.Element.Lame.Encoder do
  use Membrane.Element.Base.Filter
  alias Membrane.Element.Lame.EncoderOptions
  alias Membrane.Element.Lame.EncoderNative
  alias Membrane.Caps.Audio.Raw


  def_known_source_pads %{
    :source => {:always, [
      %Raw{format: :s8},
      %Raw{format: :u8},
    ]}
  }

  def_known_sink_pads %{
    :sink => {:always, [
      %Raw{format: :s8},
      %Raw{format: :u8},
    ]}
  }


  @doc false
  def handle_init(%EncoderOptions{}) do
    {:ok, %{
      native: nil,
      queue: << >>,
      caps: nil,
    }}
  end


  @doc false
  def handle_caps(:sink, caps, state) do

    case EncoderNative.create() do
      {:ok, native} ->
        {:ok, %{state |
          caps: caps,
          native: native,
          queue: << >> }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def handle_buffer(:sink, _caps, %Membrane.Buffer{payload: payload} = _buffer, %{native: native, queue: queue, caps: %Raw{format: format, channels: channels} = caps} = state) do
    bitstring = queue <> payload
    {:ok, bytes_per_sample} = Raw.format_to_sample_size(format)
    sample_size = bytes_per_sample * channels
    nof_full_samples = byte_size(bitstring) |> div(sample_size)
    full_sample_in_bytes = nof_full_samples * sample_size
    #TODO unit should probably be dependant on size of one sample

    <<full_buffer::binary-size(full_sample_in_bytes)-unit(8), new_remainder::binary>> = bitstring

    # Split the buffer into left and right channel
    {left_buffer, right_buffer} = split_buffer(full_buffer, bytes_per_sample)

    case EncoderNative.encode_buffer(native, left_buffer, right_buffer, nof_full_samples) do
      {:error, desc} -> {:error, desc}
      {:ok, encoded_audio} ->
        IO.inspect "#{encoded_audio}"
        {:ok, [{:send, {:source, encoded_audio}}], %{state | queue: new_remainder}}
    end
  end

  @doc false
  defp split_buffer(buffer, sample_size) do
    split_buffer(buffer, sample_size, <<>>, <<>>)
  end

  @doc false
  defp split_buffer(<<>>, _sample_size, left_buffer, right_buffer) do
    {left_buffer, right_buffer}
  end

  defp split_buffer(buffer, sample_size, left_buffer, right_buffer) do
    <<left_sample::binary-size(sample_size)-unit(8), right_sample::binary-size(sample_size)-unit(8), rest_of_buffer::binary>> = buffer
    split_buffer(rest_of_buffer, sample_size, left_buffer <> left_sample, right_buffer <> right_sample)
  end
end