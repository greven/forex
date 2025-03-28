defmodule Mix.Tasks.Forex.Export.Historic do
  @moduledoc """
  Fetch and export the historic exchange rates from the
  European Central Bank to a file.

    mix forex.export.historic

  By default the JSON encoder used is the Elixir standard library JSON encoder (only
  support in Elixir 1.18+). You can change this by setting the `:json_library` option
  in your config, for example to use `Jason` instead:

      config :forex, json_library: Jason

  Refer to `Forex.json_library/0` for more information.

  ## Examples

    * `mix forex.export.historic`
    * `mix forex.export.historic --base USD`
    * `mix forex.export.historic --symbols USD,GBP`
    * `mix forex.export.historic --output priv/data/forex`

  ## Arguments

    * `--base`      - The base currency to use. Defaults to `EUR`.
    * `--symbols`   - The currencies to fetch. Defaults to all currencies.
    * `--output`    - The output directory. Defaults to `priv/data/forex`.
    * `--help`      - Show this help message.
  """

  @shortdoc "Fetch the historic exchange rates"

  @filename "historic_rates"

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

    Forex.historic_rates!(feed_opts)
    |> Support.export!(args_opts, @filename)

    Mix.shell().info("Exchange rates exported to #{Support.output_path(args_opts, @filename)}")
  end
end
