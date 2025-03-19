defmodule Mix.Support do
  @moduledoc false

  @switches [
    base: :string,
    symbols: :string,
    output: :string,
    help: :boolean
  ]

  @default_opts [
    base: "EUR",
    symbols: nil,
    output: Path.join(:code.priv_dir(:forex), "data/forex")
  ]

  @doc """
  Take the valid feed options keys from the
  command line parse options.
  """
  def feed_opts(opts) when is_list(opts) do
    Keyword.take(opts, [:base, :symbols])
  end

  def feed_opts(_), do: []

  def parse_opts(args) do
    {opts, args, invalid} = OptionParser.parse(args, switches: @switches)

    merged_opts =
      Keyword.merge(@default_opts, opts)
      |> Map.new()
      |> Map.drop([:help])
      |> Map.replace_lazy(:symbols, &parse_symbols/1)
      |> Map.to_list()

    {merged_opts, args, invalid}
  end

  def parse_symbols(nil), do: nil

  def parse_symbols(symbols) do
    symbols
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  def output_path(opts, filename) do
    Path.join([opts[:output], "#{filename}.json"])
  end

  def export!(data, opts, filename) do
    with encoded <- encode!(data),
         {:ok, path} <- maybe_create_path(opts, filename) do
      File.write!(path, encoded)
    end
  end

  def encode!(data) when is_map(data) or is_list(data) do
    Forex.json_library().encode_to_iodata!(data)
  end

  def encode!(data), do: raise(ArgumentError, "Invalid data for export: #{inspect(data)}")

  defp maybe_create_path(opts, filename) do
    path = output_path(opts, filename)

    Path.dirname(path)
    |> File.mkdir_p()
    |> case do
      :ok -> {:ok, path}
      _ -> {:error, :failed_to_write}
    end
  end
end
