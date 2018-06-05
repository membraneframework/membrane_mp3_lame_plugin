defmodule Membrane.Element.Lame.Mixfile do
  use Mix.Project
  Application.put_env(:bundlex, :membrane_element_lame, __ENV__)

  def project do
    [
      app: :membrane_element_lame,
      compilers: ~w(bundlex) ++ Mix.compilers(),
      version: "0.1.0",
      elixir: "~> 1.6",
      description: "Membrane Multimedia Framework (Lame Element)",
      package: package(),
      name: "Membrane Element: Lame",
      source_url: link(),
      homepage_url: "https://membraneframework.org",
      preferred_cli_env: [espec: :test, format: :test],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {Membrane.Element.Lame, []}
    ]
  end

  defp link do
    "https://github.com/membraneframework/membrane-element-lame"
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => link()}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:membrane_core, git: "git@github.com:membraneframework/membrane-core.git"},
      {:membrane_caps_audio_raw,
       git: "git@github.com:membraneframework/membrane-caps-audio-raw.git"},
      {:membrane_caps_audio_mpeg,
       git: "git@github.com:membraneframework/membrane-caps-audio-mpeg.git"},
      {:membrane_common_c, git: "git@github.com:membraneframework/membrane-common-c.git"},
      {:bundlex, git: "git@github.com:radiokit/bundlex.git"},
      {:espec, "~> 1.5", only: :test}
    ]
  end
end
