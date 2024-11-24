defmodule Forex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :forex,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [ignore_modules: test_coverage_ignored()]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Forex.Application, [strategy: :one_for_one, name: Forex.Supervisor]},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:decimal, "~> 2.1"},
      {:sweet_xml, "~> 0.7"},
      {:nimble_options, "~> 1.1"},
      {:ex_doc, "~> 0.34", only: [:dev, :docs]},
      {:git_ops, "~> 2.6", only: [:dev]}
    ]
  end

  defp aliases do
    ["test.all": "test --include integration"]
  end

  defp test_coverage_ignored do
    [
      ~r(Forex.Support.*),
      Forex.Application,
      Forex.FeedError,
      Forex.DateError,
      Forex.CurrencyError,
      Forex.Fetcher.Supervisor
    ]
  end

  def cli do
    [
      preferred_envs: [
        "test.all": :test
      ]
    ]
  end
end
