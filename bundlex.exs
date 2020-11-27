defmodule Membrane.MP3.Lame.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  def natives() do
    [
      encoder: [
        interface: :nif,
        sources: ["encoder.c"],
        deps: [membrane_common_c: :membrane],
        libs: ["mp3lame", "m"],
        preprocessor: Unifex
      ]
    ]
  end
end
