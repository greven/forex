defmodule Forex.MixProject do
  use Mix.Project

  @version "0.2.2"
  @source_url "https://github.com/greven/forex"

  def project do
    [
      app: :forex,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Tests
      test_coverage: [
        ignore_modules: test_coverage_ignored()
      ],

      # Dialyzer
      dialyzer: [
        plt_add_apps: ~w(mix)a,
        flags: [
          :error_handling,
          :unknown,
          :underspecs,
          :extra_return,
          :missing_return
        ]
      ],

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "Forex",
      docs: docs()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "forex",
      files: [
        "lib",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ],
      maintainers: ["Nuno Freire"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Readme" => @source_url <> "/blob/v#{@version}/README.md",
        "Changelog" => @source_url <> "/blob/v#{@version}/CHANGELOG.md"
      }
    ]
  end

  defp description() do
    """
    A simple library for fetching and converting foreign exchange rates based on ECB data.
    """
  end

  defp docs do
    [
      name: "Forex",
      main: "readme",
      source_ref: @version,
      source_url: @source_url,
      canonical: "http://hexdocs.pm/forex",
      extras: [
        "README.md": [title: "Introduction"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:decimal, "~> 2.3"},
      {:sweet_xml, "~> 0.7"},
      {:nimble_options, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.36", only: [:dev, :docs], runtime: false},
      {:git_ops, "~> 2.6", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      "test.all": "test --include integration",
      release: "git_ops.release",
      credo: ["credo --strict"]
    ]
  end

  defp test_coverage_ignored do
    [
      ~r(Mix.*),
      Forex.FeedFixtures,
      Forex.Supervisor,
      Forex.CurrencyError,
      Forex.FeedError,
      Forex.DateError
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
