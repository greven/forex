defmodule Mix.Tasks.Forex.Export.Current do
  @moduledoc """
  Fetch and export the current exchange rates from the
  European Central Bank to a file.

    mix forex.export.current

  ## Examples

    * `mix forex.export.current`
    * `mix forex.export.current --base USD`
    * `mix forex.export.current --symbols USD,GBP`
    * `mix forex.export.current --output priv/data/forex`

  ## Arguments

    * `--base`      - The base currency to use. Defaults to `EUR`.
    * `--symbols`   - The currencies to fetch. Defaults to all currencies.
    * `--output`    - The output directory. Defaults to `priv/data/forex`.
    * `--help`      - Show this help message.
  """

  @shortdoc "Fetch the current exchange rates"

  @filename "current_rates"

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

    Forex.current_rates!(feed_opts)
    |> Support.export!(args_opts, @filename)

    Mix.shell().info("Exchange rates exported to #{Support.output_path(args_opts, @filename)}")
  end
end
