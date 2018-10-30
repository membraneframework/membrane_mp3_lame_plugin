defmodule Lame.Encoder.IntegrationTest do
  use ExUnit.Case
  alias Membrane.Pipeline

  test "Encode raw samples" do
    in_path = "fixtures/input.pcm" |> Path.expand(__DIR__)
    out_path = "/tmp/output-lame.mp3"
    on_exit(fn -> File.rm(out_path) end)

    assert {:ok, pid} =
             Pipeline.start_link(EncodingPipeline, %{in: in_path, out: out_path, pid: self()}, [])

    assert Pipeline.play(pid) == :ok
    assert_receive :eos, 300
  end
end
