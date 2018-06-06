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
      docs: docs(),
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

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      files: ["c_src", "lib", "ext", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"],
      links: %{
        "GitHub" => link(),
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:membrane_core, "~> 0.1"},
      {:membrane_caps_audio_raw, "~> 0.1"},
      {:membrane_caps_audio_mpeg, "~> 0.1"},
      {:membrane_common_c, "~> 0.1"},
      {:bundlex, "~> 0.1"},
      {:espec, "~> 1.5", only: :test}
    ]
  end
end
