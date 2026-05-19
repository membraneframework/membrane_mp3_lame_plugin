defmodule Membrane.MP3.Lame.Encoder.IntegrationTest do
  @moduledoc """
  Integration tests for the Membrane MP3 LAME encoder plugin.
  """

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
      frames = collect_frames(pid, []) |> Enum.map(&extract_main_data_begin/1)

      assert frames != [], "Expected at least one MP3 frame"

      for {main_data_begin, idx} <- Enum.with_index(frames) do
        assert main_data_begin == 0,
               "Frame #{idx} has main_data_begin=#{main_data_begin}, expected 0"
      end
    end
  end

  describe "rate_control option" do
    defp run_encoder(rate_control, opts \\ []) do
      disable_reservoir = Keyword.get(opts, :disable_reservoir, false)

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
            |> child(:encoder, %Membrane.MP3.Lame.Encoder{
              rate_control: rate_control,
              disable_reservoir: disable_reservoir
            })
            |> child(:sink, Membrane.Testing.Sink)
        )

      frames = collect_frames(pid, [])
      Pipeline.terminate(pid)
      frames
    end

    test ":cbr produces constant-size frame buffers" do
      frame_sizes = run_encoder(:cbr, disable_reservoir: true) |> Enum.map(&byte_size/1)

      assert length(frame_sizes) > 1, "Expected multiple MP3 frames, got #{length(frame_sizes)}"

      # CBR frames should be constant size, with at most 1-byte variation
      # from the MP3 padding bit. Allow the last (flush) frame to differ.
      main_sizes = Enum.drop(frame_sizes, -1)
      {min_size, max_size} = Enum.min_max(main_sizes)

      assert max_size - min_size <= 1,
             "Expected constant frame size (±1 byte padding), got range #{min_size}..#{max_size}: #{inspect(Enum.frequencies(main_sizes))}"
    end

    test "{:vbr, mode: :mtrh} produces varying frame sizes" do
      frame_sizes = run_encoder({:vbr, mode: :mtrh, quality: 4}) |> Enum.map(&byte_size/1)

      assert length(frame_sizes) > 1, "Expected multiple MP3 frames, got #{length(frame_sizes)}"

      main_sizes = Enum.drop(frame_sizes, -1)
      {min_size, max_size} = Enum.min_max(main_sizes)

      assert max_size - min_size > 1,
             "Expected varying VBR frame sizes, got range #{min_size}..#{max_size}"
    end

    test "{:vbr, mode: :abr, mean_bitrate: _} scales average frame size with target" do
      # ABR is a soft target — for highly compressible audio LAME produces
      # frames well below the requested mean. Instead of asserting a precise
      # average, verify that doubling the target meaningfully increases the
      # average frame size.
      low_avg = run_encoder({:vbr, mode: :abr, mean_bitrate: 64}) |> avg_frame_size()
      high_avg = run_encoder({:vbr, mode: :abr, mean_bitrate: 256}) |> avg_frame_size()

      assert high_avg > low_avg * 1.3,
             "Expected higher :mean_bitrate to yield larger average frames, got #{low_avg} vs #{high_avg}"
    end

    defp avg_frame_size(frames) do
      # Drop the last frame as it may be shorter
      main = Enum.drop(frames, -1)
      Enum.sum(Enum.map(main, &byte_size/1)) / length(main)
    end
  end

  defp collect_frames(pid, acc) do
    receive do
      {Pipeline, ^pid,
       {:handle_child_notification, {{:buffer, %Buffer{payload: payload}}, :sink}}} ->
        collect_frames(pid, [payload | acc])

      {Pipeline, ^pid, {:handle_child_notification, {{:end_of_stream, :input}, :sink}}} ->
        Enum.reverse(acc)
    after
      5_000 -> Enum.reverse(acc)
    end
  end

  # Extract main_data_begin from the first 9 bits after the 4-byte MP3 header
  defp extract_main_data_begin(
         <<_header::binary-size(4), main_data_begin::size(9), _remaining::bitstring>>
       ) do
    main_data_begin
  end

  defp extract_main_data_begin(_data), do: :not_mp3

  describe "Encoder forwards timestamps correctly" do
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
