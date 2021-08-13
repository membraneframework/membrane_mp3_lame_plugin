Mix.install([
  :membrane_core,
  :membrane_ffmpeg_swresample_plugin,
  :membrane_file_plugin,
  :membrane_mp3_lame_plugin,
  :membrane_portaudio_plugin
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
