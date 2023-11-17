defmodule Membrane.MP3.Lame.Mixfile do
  use Mix.Project

  @version "0.18.0"
  @github_url "https://github.com/membraneframework/membrane_mp3_lame_plugin"

  def project do
    [
      app: :membrane_mp3_lame_plugin,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      deps: deps(),
      dialyzer: dialyzer(),
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
      formatters: ["html"],
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

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:membrane_raw_audio_format, "~> 0.12.0"},
      {:membrane_caps_audio_mpeg, "~> 0.2.0"},
      {:membrane_common_c, "~> 0.16.0"},
      {:bunch, "~> 1.0"},
      {:bundlex, "~> 1.2"},
      {:espec, "~> 1.7", only: [:dev, :test]},
      {:membrane_file_plugin, "~> 0.16.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
