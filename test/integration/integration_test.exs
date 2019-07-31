defmodule Lame.Encoder.IntegrationTest do
  use ExUnit.Case
  import Membrane.Testing.Assertions
  alias Membrane.Testing.Pipeline
  alias Membrane.Element

  def make_pipeline(in_path, out_path) do
    Pipeline.start_link(%Pipeline.Options{
      elements: [
        file_src: %Element.File.Source{chunk_size: 4096, location: in_path},
        encoder: Element.Lame.Encoder,
        sink: %Element.File.Sink{location: out_path}
      ],
      links: %{
        {:file_src, :output} => {:encoder, :input},
        {:encoder, :output} => {:sink, :input}
      }
    })
  end

  test "Encode raw samples" do
    in_path = "../fixtures/input.pcm" |> Path.expand(__DIR__)
    out_path = "/tmp/output-lame.mp3"
    on_exit(fn -> File.rm(out_path) end)

    assert {:ok, pid} = make_pipeline(in_path, out_path)

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 300)
  end
end
