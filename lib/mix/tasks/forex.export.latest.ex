defmodule Mix.Tasks.Forex.Export.Latest do
  @moduledoc """
  Fetch and export the latest exchange rates from the
  European Central Bank to a file.

    mix forex.export.latest

  ## Examples

    * `mix forex.export.latest`
    * `mix forex.export.latest --base USD`
    * `mix forex.export.latest --symbols USD,GBP`
    * `mix forex.export.latest --output priv/data/forex`

  ## Arguments

    * `--base`      - The base currency to use. Defaults to `EUR`.
    * `--symbols`   - The currencies to fetch. Defaults to all currencies.
    * `--output`    - The output directory. Defaults to `priv/data/forex`.
    * `--help`      - Show this help message.
  """

  @shortdoc "Fetch the latest exchange rates"

  @filename "latest_rates"

  use Mix.Task

  alias Mix.Support

  @impl Mix.Task
  def run([help]) when help in ~w(-h --help) do
    Mix.shell().info(@moduledoc)
  end

  def run(args) do
    {args_opts, _, _} = Support.parse_opts(args)
    feed_opts = Support.feed_opts(args_opts)

    Mix.Task.run("app.start")

    Forex.latest_rates!(feed_opts)
    |> Support.export!(args_opts, @filename)

    Mix.shell().info("Exchange rates exported to #{Support.output_path(args_opts, @filename)}")
  end
end
