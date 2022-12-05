defmodule Membrane.MP3.Lame.Encoder.IntegrationTest do
  use ExUnit.Case
  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec
  alias Membrane.Testing.Pipeline

  defp make_pipeline(in_path, out_path) do
    Pipeline.start_link_supervised!(
      structure: [
        child(:file_src, %Membrane.File.Source{chunk_size: 4096, location: in_path})
        |> child(:encoder, Membrane.MP3.Lame.Encoder)
        |> child(:sink, %Membrane.File.Sink{location: out_path})
      ]
    )
  end

  defp assert_files_equal(file_a, file_b) do
    assert {:ok, a} = File.read(file_a)
    assert {:ok, b} = File.read(file_b)
    assert a == b
  end

  test "Encode raw samples" do
    in_path = "../fixtures/input.pcm" |> Path.expand(__DIR__)
    out_path = "/tmp/output-lame.mp3"
    ref_path = "../fixtures/ref.mp3" |> Path.expand(__DIR__)
    on_exit(fn -> File.rm(out_path) end)

    pid = make_pipeline(in_path, out_path)
    on_exit(fn -> Pipeline.terminate(pid, blocking?: true) end)

    assert_end_of_stream(pid, :sink, :input, 300)
    assert_files_equal(out_path, ref_path)
  end
end
