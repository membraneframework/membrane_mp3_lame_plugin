defmodule Membrane.Element.Lame.Encoder do
  use Membrane.Element.Base.Filter
  alias Membrane.Element.Lame.Encoder.Options
  alias Membrane.Element.Lame.EncoderNative
  alias Membrane.Caps.Audio.Raw
  alias Membrane.Caps.Audio.MPEG
  alias Membrane.Buffer
  use Membrane.Mixins.Log, tags: :membrane_element_lame


  def_known_source_pads %{
    :source => {:always, :pull, [
      %MPEG{
        channels: 2,
        sample_rate: 44100,
      }
    ]}
  }

  def_known_sink_pads %{
    :sink => {:always, {:pull, demand_in: :bytes}, [
      %Raw{
        format: :s24le,
        sample_rate: 44100,
        channels: 2,
      }
    ]}
  }


  @doc false
  def handle_init(%Options{} = options) do
    {:ok, %{
      native: nil,
      queue: <<>>,
    }}
  end
  
  @doc false
  def handle_prepare(:stopped, state) do
    with {:ok, native} <- EncoderNative.create
    do
      caps = %MPEG{channels: 2, sample_rate: 44100}
      {{:ok, caps: {:source, :any}}, %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end
  def handle_prepare(_, state), do: {:ok, state}

  @doc false
  def handle_demand(:source, _size, _unit, state) do
    {{:ok, demand: :sink}, state}
  end

  @doc false
  def handle_process1(:sink, %Buffer{payload: data} = buffer, _, %{native: native, queue: queue} = state) do
    to_encode = queue <> data
    with {:ok, {encoded_audio, bytes_used}} when bytes_used > 0
      <- encode_buffer(native, to_encode)
    do
      << _handled :: binary-size(bytes_used), rest :: binary >> = to_encode

      {{:ok, buffer: {:source, %Buffer{buffer | payload: encoded_audio}}}, %{ state | queue: rest }}
    else
      {:ok, {<<>>, 0}} -> {:ok, %{state | queue: to_encode}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  defp encode_buffer(native, buffer) do
    encode_buffer(native, buffer, <<>>, 0)
  end

  defp encode_buffer(_native, <<>>, acc, bytes_used) do
    {:ok, {acc, bytes_used}}
  end

  defp encode_buffer(native, buffer, acc, bytes_used) when byte_size(buffer) > 0 do
    with {:ok, {encoded_frame, frame_size}}
      <- EncoderNative.encoded_frame(native, buffer)
    do
      << _used :: binary-size(frame_size), rest :: binary >> = encoded_frame

      encode_buffer(native, rest, acc <> encoded_frame, bytes_used + frame_size)
    else
      {:error, :buflen} ->
        {:ok, {acc, bytes_used}}

      {:error, reason} ->
        warn_error "Terminating stream becouse of malformed frame", reason
        {:error, reason}
    end
  end
end
