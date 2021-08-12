Mix.install([
  {:membrane_core, "~> 0.7.0"},
  {:membrane_ffmpeg_swresample_plugin, "~> 0.7.1"},
  {:membrane_file_plugin, "~> 0.6.0"},
  {:membrane_mp3_lame_plugin, "~> 0.8.0"},
  {:membrane_portaudio_plugin, "~> 0.7.0"}
])

defmodule MP3Encoder.Pipeline do
  use Membrane.Pipeline

  alias Membrane.FFmpeg.SWResample.Converter
  alias Membrane.Caps.Audio.Raw

  @impl true
  def handle_init(filename) do
    children = [
      portaudio: Membrane.PortAudio.Source,
      converter: %Converter{
        input_caps: %Raw{channels: 2, format: :s16le, sample_rate: 48_000},
        output_caps: %Raw{channels: 2, format: :s32le, sample_rate: 44_100}
      },
      encoder: Membrane.MP3.Lame.Encoder,
      file: %Membrane.File.Sink{location: filename}
    ]

    links = [
      link(:portaudio) |> to(:converter) |> to(:encoder) |> to(:file)
    ]

    {{:ok, spec: %Membrane.ParentSpec{children: children, links: links}}, %{}}
  end
end

{:ok, pid} = MP3Encoder.Pipeline.start_link("output.mp3")
MP3Encoder.Pipeline.play(pid)
