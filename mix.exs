defmodule Membrane.MP3.Lame.Mixfile do
  use Mix.Project

  @version "0.10.0"
  @github_url "https://github.com/membraneframework/membrane_mp3_lame_plugin"

  def project do
    [
      app: :membrane_mp3_lame_plugin,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      deps: deps(),
      description: "Membrane MP3 encoder based on Lame",
      package: package(),
      name: "Membrane MP3 Lame Plugin",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs(),
      preferred_cli_env: [espec: :test, format: :test]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.MP3.Lame]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      files: ["c_src", "lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:membrane_core, "~> 0.8.0"},
      {:membrane_caps_audio_raw, "~> 0.5.0"},
      {:membrane_caps_audio_mpeg, "~> 0.2.0"},
      {:membrane_common_c, "~> 0.10.0"},
      {:bunch, "~> 1.0"},
      {:unifex, "~> 0.6.0"},
      {:ex_doc, "~> 0.22.2", only: :dev, runtime: false},
      {:espec, "~> 1.7", only: :test},
      {:membrane_file_plugin, "~> 0.7.0", only: :test}
    ]
  end
end
