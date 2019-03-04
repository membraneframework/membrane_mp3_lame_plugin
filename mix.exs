defmodule Membrane.Element.Lame.Mixfile do
  use Mix.Project

  @version "0.3.1"
  @github_url "https://github.com/membraneframework/membrane-element-lame"

  def project do
    [
      app: :membrane_element_lame,
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (Lame Element)",
      package: package(),
      name: "Membrane Element: Lame",
      source_url: @github_url,
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      files: [
        "c_src",
        "lib",
        "ext",
        "mix.exs",
        "README*",
        "LICENSE*",
        ".formatter.exs",
        "bundlex.exs"
      ],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:membrane_core, "~> 0.2.2"},
      {:membrane_caps_audio_raw, "~> 0.1"},
      {:membrane_caps_audio_mpeg, "~> 0.2"},
      {:membrane_common_c, "~> 0.2.0"},
      {:bundlex, "~> 0.1.6"},
      {:bunch, "~> 1.0"},
      {:unifex, "~> 0.2.0"},
      {:espec, "~> 1.7", only: :test},
      {:membrane_element_file, "~> 0.2.2", only: :test}
    ]
  end
end
