defmodule EncodingPipeline do
  @moduledoc false

  use Membrane.Pipeline
  alias Membrane.Element

  @impl true
  def handle_init(%{in: in_path, out: out_path, pid: pid}) do
    children = [
      file_src: %Element.File.Source{chunk_size: 4096, location: in_path},
      encoder: Element.Lame.Encoder,
      sink: %Element.File.Sink{location: out_path}
    ]

    links = %{
      {:file_src, :output} => {:encoder, :input},
      {:encoder, :output} => {:sink, :input}
    }

    spec = %Membrane.Pipeline.Spec{
      children: children,
      links: links
    }

    {{:ok, spec}, %{pid: pid}}
  end

  @impl true
  def handle_notification({:end_of_stream, :input}, :sink, %{pid: pid} = state) do
    send(pid, :eos)
    {:ok, state}
  end

  def handle_notification(_msg, _name, state) do
    {:ok, state}
  end
end
