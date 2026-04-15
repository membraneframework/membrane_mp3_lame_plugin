defmodule Membrane.MP3.Lame.Encoder.IntegrationTest do
  use ExUnit.Case
  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec
  alias Membrane.Buffer
  alias Membrane.Testing.Pipeline

  @samples_per_frame 1152
  @channels 2
  @sample_size 4
  @raw_frame_size @samples_per_frame * @sample_size * @channels

  @in_path "test/fixtures/input.pcm"
  @ref_path "test/fixtures/ref.mp3"

  defp make_pipeline(chunk_size, in_path, out_path) do
    Pipeline.start_link_supervised!(
      spec:
        child(:file_src, %Membrane.File.Source{chunk_size: chunk_size, location: in_path})
        |> child(:parser, %Membrane.RawAudioParser{
          stream_format: %Membrane.RawAudio{
            sample_format: :s32le,
            sample_rate: 44_100,
            channels: 2
          },
          overwrite_pts?: true
        })
        |> child(:encoder, Membrane.MP3.Lame.Encoder)
        |> child(:sink, %Membrane.File.Sink{location: out_path})
    )
  end

  defp assert_files_equal(file_a, file_b) do
    assert {:ok, a} = File.read(file_a)
    assert {:ok, b} = File.read(file_b)
    assert a == b
  end

  defp assert_correct_sink_buffers_pts(
         raw_pipeline,
         encoded_pipeline,
         raw_to_encoded_buffers_ratio
       ) do
    receive do
      {Pipeline, ^raw_pipeline,
       {:handle_child_notification, {{:buffer, %Buffer{pts: raw_pts}}, :sink_raw}}} ->
        encoded_pts =
          case raw_to_encoded_buffers_ratio do
            :one_to_one ->
              assert_sink_buffer(encoded_pipeline, :sink_encoded, %Buffer{pts: encoded_pts})
              encoded_pts

            :one_to_two ->
              assert_sink_buffer(encoded_pipeline, :sink_encoded, %Buffer{pts: encoded_pts})
              assert_sink_buffer(encoded_pipeline, :sink_encoded, _skip_buffer)
              encoded_pts

            :two_to_one ->
              assert_sink_buffer(encoded_pipeline, :sink_encoded, %Buffer{pts: encoded_pts})
              assert_sink_buffer(raw_pipeline, :sink_raw, _skip_buffer)
              encoded_pts
          end

        assert raw_pts == encoded_pts

        assert_correct_sink_buffers_pts(
          raw_pipeline,
          encoded_pipeline,
          raw_to_encoded_buffers_ratio
        )

      {Pipeline, ^raw_pipeline,
       {:handle_child_notification, {{:end_of_stream, :input}, :sink_raw}}} ->
        :ok
    end
  end

  defp perform_timestamp_test(chunk_size, raw_to_encoded_buffer_ratio) do
    pipeline_head =
      child(%Membrane.File.Source{chunk_size: chunk_size, location: @in_path})
      |> child(%Membrane.RawAudioParser{
        stream_format: %Membrane.RawAudio{
          sample_format: :s32le,
          sample_rate: 44_100,
          channels: 2
        },
        overwrite_pts?: true
      })

    raw_pipeline =
      Pipeline.start_link_supervised!(
        spec:
          pipeline_head
          |> child(:sink_raw, Membrane.Testing.Sink)
      )

    encoded_pipeline =
      Pipeline.start_link_supervised!(
        spec:
          pipeline_head
          |> child(:encoder, Membrane.MP3.Lame.Encoder)
          |> child(:sink_encoded, Membrane.Testing.Sink)
      )

    assert_correct_sink_buffers_pts(raw_pipeline, encoded_pipeline, raw_to_encoded_buffer_ratio)
  end

  @tag :tmp_dir
  test "Encode raw samples", ctx do
    out_path = Path.join(ctx.tmp_dir, "output-lame.mp3")

    pid = make_pipeline(4096, @in_path, out_path)

    assert_end_of_stream(pid, :sink, :input, 300)
    assert_files_equal(out_path, @ref_path)
    Pipeline.terminate(pid)
  end

  describe "disable_reservoir option" do
    test "produces frames with main_data_begin always 0" do
      pid =
        Pipeline.start_link_supervised!(
          spec:
            child(:file_src, %Membrane.File.Source{chunk_size: 4096, location: @in_path})
            |> child(:parser, %Membrane.RawAudioParser{
              stream_format: %Membrane.RawAudio{
                sample_format: :s32le,
                sample_rate: 44_100,
                channels: 2
              },
              overwrite_pts?: true
            })
            |> child(:encoder, %Membrane.MP3.Lame.Encoder{disable_reservoir: true})
            |> child(:sink, Membrane.Testing.Sink)
        )

      # Collect frames and extract main_data_begin from each
      frames = collect_main_data_begins(pid, [])

      assert length(frames) > 0, "Expected at least one MP3 frame"

      for {main_data_begin, idx} <- Enum.with_index(frames) do
        assert main_data_begin == 0,
               "Frame #{idx} has main_data_begin=#{main_data_begin}, expected 0"
      end
    end
  end

  describe "cbr option" do
    test "produces constant-size frame buffers" do
      pid =
        Pipeline.start_link_supervised!(
          spec:
            child(:file_src, %Membrane.File.Source{chunk_size: 4096, location: @in_path})
            |> child(:parser, %Membrane.RawAudioParser{
              stream_format: %Membrane.RawAudio{
                sample_format: :s32le,
                sample_rate: 44_100,
                channels: 2
              },
              overwrite_pts?: true
            })
            |> child(:encoder, %Membrane.MP3.Lame.Encoder{cbr: true, disable_reservoir: true})
            |> child(:sink, Membrane.Testing.Sink)
        )

      # Collect frame sizes from sink buffers
      frame_sizes = collect_frame_sizes(pid, [])

      assert length(frame_sizes) > 1, "Expected multiple MP3 frames, got #{length(frame_sizes)}"

      # CBR frames should be constant size, with at most 1-byte variation
      # from the MP3 padding bit (used to maintain exact average bitrate).
      # Allow the last frame to differ (flush frame may be shorter).
      main_sizes = Enum.drop(frame_sizes, -1)
      {min_size, max_size} = Enum.min_max(main_sizes)

      assert max_size - min_size <= 1,
             "Expected constant frame size (±1 byte padding), got range #{min_size}..#{max_size}: #{inspect(Enum.frequencies(main_sizes))}"
    end
  end

  defp collect_frame_sizes(pid, acc) do
    receive do
      {Pipeline, ^pid,
       {:handle_child_notification, {{:buffer, %Buffer{payload: payload}}, :sink}}} ->
        collect_frame_sizes(pid, [byte_size(payload) | acc])

      {Pipeline, ^pid, {:handle_child_notification, {{:end_of_stream, :input}, :sink}}} ->
        Enum.reverse(acc)
    after
      5_000 -> Enum.reverse(acc)
    end
  end

  # Collect main_data_begin values from each frame buffer via Testing.Sink
  defp collect_main_data_begins(pid, acc) do
    receive do
      {Pipeline, ^pid,
       {:handle_child_notification, {{:buffer, %Buffer{payload: payload}}, :sink}}} ->
        main_data_begin = extract_main_data_begin(payload)
        collect_main_data_begins(pid, [main_data_begin | acc])

      {Pipeline, ^pid, {:handle_child_notification, {{:end_of_stream, :input}, :sink}}} ->
        Enum.reverse(acc)
    after
      5_000 -> Enum.reverse(acc)
    end
  end

  # Extract main_data_begin from the first 9 bits after the 4-byte MP3 header
  defp extract_main_data_begin(<<_header::binary-size(4), main_data_begin::size(9), _::bitstring>>) do
    main_data_begin
  end

  defp extract_main_data_begin(_), do: :not_mp3

  describe "Encoder forwards timestamps corretly" do
    test "when one input buffer contains exactly one MP3 frame" do
      perform_timestamp_test(@raw_frame_size, :one_to_one)
    end

    test "when one input buffer contains exactly two MP3 frames" do
      perform_timestamp_test(@raw_frame_size * 2, :one_to_two)
    end

    test "when two input buffers contain exactly one MP3 frame" do
      perform_timestamp_test(round(@raw_frame_size / 2), :two_to_one)
    end
  end
end
