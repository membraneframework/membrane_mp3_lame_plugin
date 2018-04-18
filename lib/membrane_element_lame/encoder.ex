defmodule Membrane.Element.Lame.Encoder do
  @moduledoc """
  Element encoding raw audio into MPEG-1, layer 3 format
  """
  use Membrane.Element.Base.Filter
  alias Membrane.Caps.Audio.Raw
  alias Membrane.Caps.Audio.MPEG
  alias Membrane.Buffer
  alias __MODULE__
  alias __MODULE__.Native

  use Membrane.Mixins.Log, tags: :membrane_element_lame

  @samples_per_frame 1152
  @channels 2
  @sample_size 4

  def_options bitrate: [type: :integer, default: 192, description: "Bitrate in kbit/sec"],
              quality: [
                type: :atom,
                default: :medium,
                spec: :low | :medium | :high,
                description: "Quality of the encoded audio"
              ]

  def_known_source_pads source:
                          {:always, :pull,
                           {
                             MPEG,
                             channels: 2, sample_rate: 44100, layer: :layer3, version: :v1
                           }}

  def_known_sink_pads sink:
                        {:always, {:pull, demand_in: :bytes},
                         {
                           Raw,
                           format: :s32le, sample_rate: 44100, channels: 2
                         }}

  @impl true
  def handle_init(%Encoder{} = options) do
    {:ok,
     %{
       native: nil,
       queue: <<>>,
       options: options,
       eos: false
     }}
  end

  @impl true
  def handle_prepare(:stopped, state) do
    with quality_val <- state.options.quality |> map_quality_to_value,
         {:ok, native} <-
           Native.create(
             @channels,
             state.options.bitrate,
             quality_val
           ) do
      caps = %MPEG{channels: 2, sample_rate: 44100, version: :v1, layer: :layer3, bitrate: 192}
      {{:ok, caps: {:source, caps}}, %{state | native: native}}
    else
      :invalid_quality = reason ->
        {{:error, reason}, state}
      {:error, reason} ->
        {{:error, reason}, state}
    end
  end

  def handle_prepare(_, state), do: {:ok, state}

  @impl true
  def handle_demand(:source, size, :bytes, _, state) do
    {{:ok, demand: {:sink, size}}, state}
  end

  def handle_demand(:source, size, :buffers, _, state) do
    {{:ok, demand: {:sink, size * 5000}}, state}
  end

  @impl true
  def handle_event(:sink, %Membrane.Event{type: :eos} = evt, params, state) do
    super(:sink, evt, params, %{state | eos: true})
  end

  def handle_event(pad, evt, params, state) do
    super(pad, evt, params, state)
  end

  @impl true
  def handle_caps(:sink, _, _, state) do
    {:ok, state}
  end

  @impl true
  def handle_process1(
        :sink,
        %Buffer{payload: data},
        _,
        %{native: native, queue: queue, eos: eos} = state
      ) do
    to_encode = queue <> data

    with {:ok, {encoded_audio, bytes_used}} when bytes_used > 0 <-
           encode_buffer(native, to_encode, state) do
      <<_handled::binary-size(bytes_used), rest::binary>> = to_encode

      buffers = Enum.reverse(encoded_audio)

      event =
        if byte_size(rest) == 0 && eos do
          debug("EOS send")
          [event: {:source, Membrane.Event.eos()}]
        else
          []
        end

      {{:ok, buffers ++ event}, %{state | queue: rest}}
    else
      {:ok, {[], 0}} -> {:ok, %{state | queue: to_encode}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  # init
  defp encode_buffer(native, buffer, state) do
    raw_frame_size = @samples_per_frame * @sample_size * @channels
    encode_buffer(native, buffer, [], 0, raw_frame_size, state[:eos])
  end

  # handle single frame
  defp encode_buffer(native, buffer, acc, bytes_used, raw_frame_size, is_eos)
       when byte_size(buffer) >= raw_frame_size or is_eos do
    {raw_frame, rest} =
      case buffer do
        <<used::binary-size(raw_frame_size), rest::binary>> -> {used, rest}
        <<partial::binary>> -> {partial, <<>>}
      end

    with {:ok, encoded_frame} <- Native.encode_frame(native, raw_frame) do
      frame_size = min(byte_size(buffer), raw_frame_size)
      encoded_buffer = {:buffer, {:source, %Buffer{payload: encoded_frame}}}

      encode_buffer(
        native,
        rest,
        [encoded_buffer | acc],
        bytes_used + frame_size,
        raw_frame_size,
        is_eos
      )
    else
      {:error, :buflen} ->
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

  defp map_quality_to_value(:low), do: 7
  defp map_quality_to_value(:medium), do: 5
  defp map_quality_to_value(:high), do: 2

  defp map_quality_to_value(quality) when is_integer(quality) and quality >= 0 and quality <= 9,
    do: quality

  defp map_quality_to_value(_), do: :invalid_quality
end
