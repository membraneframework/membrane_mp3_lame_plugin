defmodule Membrane.Element.Lame.Mixfile do
  use Mix.Project

  @version "0.1.2"
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
      {:membrane_core, github: "membraneframework/membrane-core", override: true},
      {:membrane_caps_audio_raw, "~> 0.1.1", github: "membraneframework/membrane-caps-audio-raw"},
      {:membrane_caps_audio_mpeg, "~> 0.1.0"},
      {:membrane_common_c, "~> 0.1"},
      {:bundlex, "~> 0.1", github: "membraneframework/bundlex", override: true},
      {:bunch, "~> 0.1", github: "membraneframework/bunch", override: true},
      {:unifex, github: "membraneframework/unifex"},
      {:espec, "~> 1.6", only: :test},
      {:membrane_element_file,
       github: "membraneframework/membrane-element-file",
       branch: "feature/release_v0.2",
       only: :test}
    ]
  end
end
