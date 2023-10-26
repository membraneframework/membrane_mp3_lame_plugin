defmodule Membrane.MP3.Lame.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  defp get_lame_url() do
    url_prefix =
      "https://github.com/membraneframework-precompiled/precompiled_lame/releases/latest/download/lame"

    case Bundlex.get_target() do
      %{os: "linux"} ->
        {:precompiled, "#{url_prefix}_linux.tar.gz"}

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_intel.tar.gz"}

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_arm.tar.gz"}

      _other ->
        nil
    end
  end

  def natives() do
    [
      encoder: [
        interface: :nif,
        sources: ["encoder.c"],
        deps: [membrane_common_c: :membrane],
        os_deps: [{[get_lame_url(), :pkg_config], "mp3lame"}],
        preprocessor: Unifex
      ]
    ]
  end
end
