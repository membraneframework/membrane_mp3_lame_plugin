defmodule Membrane.Element.Lame.Encoder do
  @moduledoc """
  Element encoding raw audio into MPEG-1, layer 3 format
  """
  use Membrane.Element.Base.Filter
  alias Membrane.Caps.Audio.{MPEG, Raw}
  alias Membrane.Buffer
  alias __MODULE__.Native
  alias Membrane.Event.EndOfStream

  use Membrane.Log, tags: :membrane_element_lame

  @samples_per_frame 1152
  @channels 2
  @sample_size 4

  def_options bitrate: [
                type: :integer,
                default: 192,
                description: "Output bitrate of encoded stream in kbit/sec."
              ],
              quality: [
                type: :atom,
                default: :medium,
                spec: :low | :medium | :high,
                description: "Quality of the encoded audio."
              ]

  def_output_pads output: [
                    caps: {MPEG, channels: 2, sample_rate: 44_100, layer: :layer3, version: :v1}
                  ]

  def_input_pads input: [
                   demand_unit: :bytes,
                   caps: {Raw, format: :s32le, sample_rate: 44_100, channels: 2}
                 ]

  @impl true
  def handle_init(options) do
    {:ok,
     %{
       native: nil,
       queue: <<>>,
       options: options,
       raw_frame_size: MPEG.samples_per_frame(:v1, :layer3) * @sample_size * @channels
     }}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state) do
    with {:ok, quality_val} <- state.options.quality |> map_quality_to_value,
         {:ok, native} <-
           Native.create(
             @channels,
             state.options.bitrate,
             quality_val
           ) do
      caps = %MPEG{channels: 2, sample_rate: 44_100, version: :v1, layer: :layer3, bitrate: 192}
      {{:ok, caps: {:output, caps}}, %{state | native: native}}
    else
      {:error, :invalid_quality} ->
        {{:error, :invalid_quality}, state}

      {:error, reason} ->
        {{:error, reason}, state}
    end
  end

  @impl true
  def handle_demand(:output, size, :bytes, _ctx, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  def handle_demand(:output, bufs, :buffers, _ctx, %{raw_frame_size: size} = state) do
    {{:ok, demand: {:input, size * bufs}}, state}
  end

  @impl true
  def handle_caps(:input, _caps, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_event(:input, %EndOfStream{}, _ctx, %{queue: ""} = state) do
    {{:ok, notify: {:end_of_stream, :input}, event: %EndOfStream{}}, state}
  end

  def handle_event(:input, %EndOfStream{}, _ctx, %{native: native, queue: queue} = state) do
    with {:ok, {encoded_audio, bytes_used}} when bytes_used == byte_size(queue) <-
           encode_buffer(native, queue, true) do
      buffers = Enum.reverse(encoded_audio)

      {{:ok, buffers}, %{state | queue: ""}}
    else
      {:ok, {_bufs, _bytes_used}} -> {{:error, :invalid_last_frame}, state}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_process(
        :input,
        %Buffer{payload: data},
        %Ctx.Process{pads: pads},
        %{native: native, queue: queue} = state
      ) do
    to_encode = queue <> data

    with {:ok, {encoded_audio, bytes_used}} when bytes_used > 0 <-
           encode_buffer(native, to_encode, pads.input[:end_of_stream?]) do
      <<_handled::binary-size(bytes_used), rest::binary>> = to_encode

      buffers = Enum.reverse(encoded_audio)

      {{:ok, buffers}, %{state | queue: rest}}
    else
      {:ok, {[], 0}} -> {:ok, %{state | queue: to_encode}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  # init
  defp encode_buffer(native, buffer, is_eos) do
    raw_frame_size = @samples_per_frame * @sample_size * @channels

    case encode_buffer(native, buffer, [], 0, raw_frame_size, is_eos) do
      {:error, reason} ->
        {:error, reason}

      {:ok, _} = return_value ->
        return_value
    end
  end

  # handle single frame
  defp encode_buffer(native, buffer, acc, bytes_used, raw_frame_size, is_eos)
       when byte_size(buffer) >= raw_frame_size or is_eos do
    {raw_frame, rest} =
      case buffer do
        <<used::binary-size(raw_frame_size), rest::binary>> -> {used, rest}
        <<partial::binary>> -> {partial, <<>>}
      end

    with {:ok, encoded_frame} <- Native.encode_frame(raw_frame, native) do
      frame_size = min(byte_size(buffer), raw_frame_size)
      encoded_buffer = {:buffer, {:output, %Buffer{payload: encoded_frame}}}

      encode_buffer(
        native,
        rest,
        [encoded_buffer | acc],
        bytes_used + frame_size,
        raw_frame_size,
        is_eos
      )
    else
      {:error, :framelen} ->
        {:ok, {acc, bytes_used}}

      {:error, reason} ->
        warn_error("Terminating stream because of malformed frame", reason)
        {:error, reason}
    end
  end

  # Not enough samples for a frame
  defp encode_buffer(_native, _partial_buffer, acc, bytes_used, _raw_frame_size, false) do
    {:ok, {acc, bytes_used}}
  end

  defp map_quality_to_value(:low), do: {:ok, 7}
  defp map_quality_to_value(:medium), do: {:ok, 5}
  defp map_quality_to_value(:high), do: {:ok, 2}
  defp map_quality_to_value(quality) when quality in 0..9, do: {:ok, quality}
  defp map_quality_to_value(_), do: {:error, :invalid_quality}
end
