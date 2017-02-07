defmodule Membrane.Element.Lame.Encoder do
  use Membrane.Element.Base.Filter


  @doc false
  def handle_init(%AggregatorOptions{interval: interval}) do
    {:ok, %{
      native: nil,
      queue: << >>,
      caps: nil,
    }}
  end


  @doc false
  def handle_caps({:sink, caps}, %{native: native} = state) do

    case EncoderNative.create() do
      {:ok, native} ->
        {:ok, %{state |
          native: native,
          queue: << >> }}

      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc false
  def handle_buffer({:sink, %Membrane.Buffer{payload: payload} = buffer}, %{native: native, queue: queue} = state) do

    case EncoderNative.encode_buffer(native, queue <> payload) do
      {:error, desc} ->
        {:error, desc}
      {encoded_audio} ->
        {:send_buffer, {caps, encoded_audio}, state}
    end
  end

end