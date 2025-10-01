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
        os_deps: [
          mp3lame: [
            {:precompiled,
             Membrane.PrecompiledDependencyProvider.get_dependency_url(:lame, version: "3.100")},
            :pkg_config
          ]
        ],
        preprocessor: Unifex
      ]
    ]
  end
end
