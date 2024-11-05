defmodule Forex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :forex,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Forex.Application, [strategy: :one_for_one, name: Forex.Supervisor]},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4"},
      {:decimal, "~> 2.1"},
      {:sweet_xml, "~> 0.7"},
      {:nimble_options, "~> 1.1"},
      {:phoenix, "~> 1.7", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: [:dev, :docs]}
    ]
  end

  defp aliases do
    []
  end
end
