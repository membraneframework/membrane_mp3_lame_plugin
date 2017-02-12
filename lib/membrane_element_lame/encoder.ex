defmodule Membrane.Element.Lame.Encoder do
  use Membrane.Element.Base.Filter
  alias Membrane.Element.Lame.EncoderOptions
  alias Membrane.Element.Lame.EncoderNative
  alias Membrane.Caps.Audio.Raw


  @doc false
  def handle_init(%EncoderOptions{}) do
    {:ok, %{
      native: nil,
      queue: << >>,
      caps: nil,
    }}
  end


  @doc false
  def handle_caps({:sink, caps}, %{native: native} = state) do

    case EncoderNative.create(caps) do
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
  def handle_buffer({:sink, %Membrane.Buffer{payload: payload} = buffer}, %{native: native, queue: queue, caps: caps} = state) do

    bitstring = queue <> payload
    %Raw{format: format, channels: channels} = caps
    {:ok, bytes_per_sample} = Raw.format_to_sample_size(format)
    sample_size = bytes_per_sample * channels
    nof_full_samples = byte_size(bitstring) |> div(sample_size)
    full_sample_in_bytes = nof_full_samples * sample_size
    #TODO unit should probably be dependant on size of one sample
    <<full_buffer::size(full_sample_in_bytes)-unit(8), new_remainder::binary>> = bitstring

    {left_buffer, right_buffer} = split_buffer(full_buffer)

    case EncoderNative.encode_buffer(native, left_buffer, right_buffer) do
      {:error, desc} ->
        {:error, desc}
      {encoded_audio} ->
        {:ok, [{:send, {:source, buffer}}], %{state | queue: new_remainder}}
    end
  end

  @doc false
  defp split_buffer(buffer) do
    [x | tail1] = buffer
    [y | tail2] = tail1
    {left, right} = split_buffer(tail1)
    {[x | left], [y | right]}
  end

  defp split_buffer([]) do
    {[],[]}
  end

end