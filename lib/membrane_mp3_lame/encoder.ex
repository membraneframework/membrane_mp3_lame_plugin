defmodule Membrane.MP3.Lame.Encoder do
  @moduledoc """
  Element encoding raw audio into MPEG-1, layer 3 format
  """
  use Membrane.Filter

  require Membrane.Logger

  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.Caps.Audio.MPEG
  alias Membrane.RawAudio

  @samples_per_frame 1152
  @channels 2
  @sample_size 4

  def_output_pad :output,
    accepted_format: %MPEG{channels: 2, sample_rate: 44_100, layer: :layer3, version: :v1}

  def_input_pad :input,
    accepted_format:
      any_of(
        %RawAudio{sample_format: :s32le, sample_rate: 44_100, channels: 2},
        Membrane.RemoteStream
      )

  def_options gapless_flush: [
                spec: boolean(),
                default: true,
                description: """
                When this option is set to true, encoder will be flushed without
                outputting any tags and allowing to play such file gaplessly
                if concatenated with another file.
                """
              ],
              bitrate: [
                spec: integer(),
                default: 192,
                description: """
                Output bitrate of encoded stream in kbit/sec.
                """
              ],
              quality: [
                default: 5,
                spec: non_neg_integer,
                description: """
                Value of this parameter affects quality by selecting one of the algorithms
                for encoding: `0` being best (and very slow) and `9` being worst.

                Recommended values:
                  * `2` - near-best quality, not too slow
                  * `5` - good quality, fast
                  * `7` - ok quality, really fast
                """
              ]

  @impl true
  def handle_init(_ctx, options) do
    {[],
     %{
       native: nil,
       queue: <<>>,
       options: options,
       raw_frame_size: MPEG.samples_per_frame(:v1, :layer3) * @sample_size * @channels
     }}
  end

  @impl true
  def handle_setup(_ctx, state) do
    quality_val = state.options.quality |> map_quality_to_value!

    with {:ok, native} <-
           Native.create(
             @channels,
             state.options.bitrate,
             quality_val
           ) do
      {[], %{state | native: native}}
    else
      {:error, reason} ->
        raise "Error initializing mpeg: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_playing(_ctx, state) do
    stream_format = %MPEG{
      channels: 2,
      sample_rate: 44_100,
      version: :v1,
      layer: :layer3,
      bitrate: 192
    }

    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_stream_format(:input, _stream_format, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_end_of_stream(:input, __ctx, %{queue: ""} = state) do
    {[notify_parent: {:end_of_stream, :input}, end_of_stream: :output], state}
  end

  def handle_end_of_stream(:input, _ctx, state) do
    %{native: native, queue: queue, options: options} = state

    buffers = encode_last_frame!(native, queue, options.gapless_flush)
    actions = [end_of_stream: :output, notify_parent: {:end_of_stream, :input}]
    {buffers ++ actions, %{state | queue: ""}}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: data}, _ctx, state) do
    %{native: native, queue: queue} = state
    to_encode = queue <> data

    with {:ok, {encoded_bufs, bytes_used}} when bytes_used > 0 <- encode_buffer(native, to_encode) do
      <<_handled::binary-size(bytes_used), rest::binary>> = to_encode
      {[buffer: {:output, encoded_bufs}], %{state | queue: rest}}
    else
      {:ok, {[], 0}} -> {[], %{state | queue: to_encode}}
      {:error, reason} -> raise "Error #{inspect(reason)}"
    end
  end

  # init
  defp encode_buffer(native, buffer) do
    raw_frame_size = @samples_per_frame * @sample_size * @channels

    encode_buffer(native, buffer, [], 0, raw_frame_size)
  end

  # handle single frame
  defp encode_buffer(native, buffer, acc, bytes_used, raw_frame_size)
       when byte_size(buffer) >= raw_frame_size do
    <<raw_frame::binary-size(raw_frame_size), rest::binary>> = buffer

    with {:ok, encoded_frame} <- Native.encode_frame(raw_frame, native) do
      encoded_buffer = %Buffer{payload: encoded_frame}

      encode_buffer(
        native,
        rest,
        [encoded_buffer | acc],
        bytes_used + raw_frame_size,
        raw_frame_size
      )
    else
      {:error, reason} ->
        Membrane.Logger.error("Terminating stream because of malformed frame. Reason: #{reason}")
        {:error, reason}
    end
  end

  # Not enough samples for a frame
  defp encode_buffer(_native, _partial_buffer, acc, bytes_used, _raw_frame_size) do
    {:ok, {acc |> Enum.reverse(), bytes_used}}
  end

  defp encode_last_frame!(native, queue, gapless?) do
    with {:ok, encoded_frame} <- Native.encode_frame(queue, native),
         {:ok, flushed_frame} <- Native.flush(gapless?, native) do
      bufs =
        [encoded_frame, flushed_frame]
        |> Enum.flat_map(fn
          "" -> []
          frame -> [%Buffer{payload: frame}]
        end)

      [buffer: {:output, bufs}]
    else
      {:error, reason} ->
        Membrane.Logger.error(
          "Terminating stream because of malformed last frame. Reason: #{reason}"
        )

        raise "Error #{inspect(reason)}"
    end
  end

  defp map_quality_to_value!(quality) when quality in 0..9, do: quality

  defp map_quality_to_value!(value),
    do: raise("Error parsing quality argument: #{inspect(value)}")
end
