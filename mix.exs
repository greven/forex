defmodule Forex.MixProject do
  use Mix.Project

  def project do
    [
      app: :forex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4"},
      {:nebulex, "~> 2.6"},
      {:sweet_xml, "~> 0.7"},
      {:benchee, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.31", only: [:dev, :docs]}
    ]
  end
end
