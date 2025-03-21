defmodule Forex do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
             |> String.replace("### Usage Information", "### Usage Information {: .info}")

  @typedoc """
  The currency code is a three-letter code that represents a currency,
  in accordance with the ISO 4217 standard.
  It can be either a string or an atom.
  """
  @type currency_code :: String.t() | atom()

  @typedoc """
  A currency rate, represented as a map with the currency code as the key
  and the rate as the value. The rate can be either a Decimal or a string.
  """
  @type rate :: %{currency_code() => Decimal.t() | String.t()}

  # A date that can be either a string in the ISO 8601 format, a Date struct
  # or a tuple with the date components in the format `{year, month, day}`.
  @typep maybe_date :: String.t() | tuple() | Date.t()

  import Forex.Support

  alias Forex.Currency
  alias Forex.Fetcher

  ## Options

  defp options_schema do
    NimbleOptions.new!(
      base: [type: {:in, currency_schema_options()}, default: :eur],
      format: [type: {:in, ~w(decimal string)a}, default: :decimal],
      round: [type: {:or, [:integer, nil]}, default: 5],
      symbols: [
        type: {:or, [{:list, {:in, currency_schema_options()}}, nil]},
        default: nil
      ],
      keys: [type: {:in, ~w(strings atoms)a}, default: :atoms],
      use_cache: [type: :boolean, default: true],
      feed_fn: [type: :mfa, default: nil]
    )
  end

  @doc """
  Validate and return the options for the Forex module functions,
  using default values if the options are not provided.

  ## Options

  * `:base` - The base currency to convert rates to (default: `:eur`)
  * `:format` - Format of rate values (`:decimal` or `:string`, default: `:decimal`)
  * `:round` - Decimal places for rounding (default: `5`)
  * `:symbols` - Currency codes to include (default: `nil` for all currencies)
  * `:keys` - Map key format (`:atoms` or `:strings`, default: `:atoms`)
  * `:use_cache` - Whether to use cached rates (default: `true`)
  * `:feed_fn` - Optional custom feed function as `{module, function, args}` (default: `nil`)
  """
  def options(opts \\ []) do
    NimbleOptions.validate!(opts, options_schema())
    |> Enum.into(%{})
  end

  @doc """
  Returns the configured JSON encoding library for Forex.
  The default is the `Jason` library.

  The JSON library must implement the `encode/1` function.

  The JSON library is only required when using the mix tasks
  to export the exchange rates to a JSON file, otherwise this
  setting can be ignored.

  To customize the JSON library, including the following
  in your `config/config.exs`:

      config :forex, :json_library, AlternativeJsonLibrary

  The library must implement the `encode_to_iodata!/2` function.

  """
  def json_library do
    Application.get_env(:forex, :json_library, Jason)
  end

  # The allowed currency codes for the schema options
  defp currency_schema_options do
    string_keys_upper = available_currencies(:strings)
    string_keys_lower = Enum.map(string_keys_upper, &String.downcase/1)

    atom_keys_lower = available_currencies(:atoms)

    atom_keys_upper =
      Enum.map(atom_keys_lower, fn k ->
        Atom.to_string(k)
        |> String.upcase()
        |> String.to_atom()
      end)

    string_keys_lower ++ string_keys_upper ++ atom_keys_lower ++ atom_keys_upper
  end

  ## Currencies

  @doc """
  Return a list of all available currencies ISO 4217 codes.
  """
  def available_currencies(keys \\ :atoms)

  def available_currencies(:strings) do
    Currency.available(:strings)
    |> Map.keys()
  end

  def available_currencies(:atoms) do
    Currency.available(:atoms)
    |> Map.keys()
  end

  @doc """
  Return a list of all available currencies.
  """
  def list_currencies(keys \\ :atoms)
  def list_currencies(:atoms), do: Currency.available(:atoms)
  def list_currencies(:strings), do: Currency.available(:strings)

  @doc """
  Return a list of all available currencies in the format
  `%{currency_code() => currency_name()}`.
  Useful for input forms, selects, etc.
  """
  def currency_options(keys \\ :atoms)

  def currency_options(:atoms) do
    list_currencies(:atoms)
    |> Enum.map(fn {code, currency} ->
      {currency.name, code}
    end)
  end

  def currency_options(:strings) do
    list_currencies(:strings)
    |> Enum.map(fn {code, currency} ->
      {currency.name, code}
    end)
  end

  @doc """
  Get the currency information for the given ISO code.
  """
  def get_currency(currency_code),
    do: Currency.get(currency_code)

  @doc """
  Get the currency information for the given ISO code.
  Like `get_currency/1`, but raises an error if the currency is not found.
  """
  def get_currency!(currency_code),
    do: Currency.get!(currency_code)

  @doc """
  Exchange a given amount from one currency to another.
  It will use the cached exchange rates from the European Central
  Bank (ECB) or fetch the latest rates if the cache is disabled.

  ## Options

  * `:format` - The format of the rate value. Supported values are `:decimal` and `:string`. The default is `:decimal`.
  * `:round` - The number of decimal places to round the rate value to. The default is `4`.

  ## Examples

  ```elixir
  iex> Forex.exchange(100, "USD", "EUR")
  {:ok, Decimal.new("91.86100")}

  iex> Forex.exchange(420, :eur, :gbp, format: :string)
  {:ok, "353.12760"}

  iex> Forex.exchange(123, :gbp, :usd, format: :string, round: 1)
  {:ok, "159.3"}
  ```
  """
  @spec exchange(number() | Decimal.t(), currency_code(), currency_code(), keyword()) ::
          {:ok, Decimal.t()} | {:error, term}
  def exchange(amount, from, to, opts \\ []),
    do: Currency.exchange(amount, from, to, opts)

  @doc """
  Same as `exchange/3`, but raises an error if the request fails.
  """
  def exchange!(amount, from, to, opts \\ []),
    do: Currency.exchange!(amount, from, to, opts)

  ## Exchange Rates

  @doc """
  Fetch the latest exchange rates from the European Central Bank (ECB).

  ## Return Value

  Returns `{:ok, %{base: atom(), date: Date.t(), rates: map()}}` on success where:
  - `base` is the base currency code
  - `date` is the reference date
  - `rates` is a map of currency codes to rate values

  ## Arguments

  * `opts` - Options:
    * `:format` - Format of rates (`:decimal` or `:string`, default: `:decimal`)
    * `:base` - Base currency (default: `EUR`)
    * `:symbols` - List of currency codes to include
    * `:keys` - Key format in rates map (`:atoms` or `:strings`)
    * `:use_cache` - Whether to use cached rates (default: `true`)

  ## Examples

  ```elixir
  {:ok, %{base: :eur, date: ~D[2025-03-12], rates: %{usd: Decimal.new("1.1234"), jpy: Decimal.new("120.1234"), ...}}}
  ```
  """
  @spec current_rates(keyword) :: {:ok, rate()} | {:error, term}
  def current_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    case Fetcher.get(:current_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      {:ok, entries} ->
        result =
          Enum.map(entries, fn %{time: datetime, rates: rates} ->
            %{
              date: map_date(datetime),
              base: Map.get(opts, :base),
              rates: map_rates(rates, options(opts))
            }
          end)
          |> List.first()

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `current_rates/1`, but raises an error if the request fails.
  """
  @spec current_rates!(keyword) :: rate()
  def current_rates!(opts \\ []) when is_list(opts) do
    case current_rates(opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Fetch the exchange rates for the last ninety days
  from the European Central Bank (ECB).

  Note that rates are only available on working days.

  ## Arguments

  Same options as `current_rates/1`.
  """
  @spec last_ninety_days_rates(keyword) :: {:ok, [rate()]} | {:error, term}
  def last_ninety_days_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    case Fetcher.get(:last_ninety_days_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      {:ok, entries} ->
        results =
          entries
          |> Stream.map(fn %{time: datetime, rates: rates} ->
            %{
              date: map_date(datetime),
              base: Map.get(opts, :base),
              rates: map_rates(rates, options(opts))
            }
          end)
          |> Enum.filter(fn %{date: date} -> date != nil end)

        {:ok, results}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `last_ninety_days_rates/1`, but raises an error if the request fails.
  """
  @spec last_ninety_days_rates!(keyword) :: [rate()]
  def last_ninety_days_rates!(opts \\ []) when is_list(opts) do
    case last_ninety_days_rates(opts) do
      {:ok, entries} -> entries
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Fetch the historic exchange rates feed from the European
  Central Bank (ECB) for any working day since 4 January 1999.

  By default, the historic rates are not automatically fetched when using
  the Fetcher (scheduler) module, since the whole file is returned this avoids excessive memory
  usage when caching the results if not needed. To fetch and cache the historic rates,
  you need to manually call this function.

  Same options as `current_rates/1`.
  """
  @spec historic_rates(keyword) :: {:ok, [rate()]} | {:error, term}
  def historic_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    case Fetcher.get(:historic_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      {:ok, entries} ->
        results =
          entries
          |> Stream.map(fn %{time: datetime, rates: rates} ->
            %{
              date: map_date(datetime),
              base: Map.get(opts, :base),
              rates: map_rates(rates, opts)
            }
          end)
          |> Enum.filter(fn %{date: date} -> date != nil end)

        {:ok, results}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `historic_rates/1`, but raises an error if the request fails.
  """
  @spec historic_rates!(keyword) :: [rate()]
  def historic_rates!(opts \\ []) when is_list(opts) do
    case historic_rates(opts) do
      {:ok, entries} -> entries
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Get a specific date from the historic exchange rates feed.
  It returns either an `{:ok, rate()}` if the rate was successfully
  retrieved or an `{:error, reasons}` if the rate was not found.

  ## Arguments

  * `date` - The date to get the rate for. `date` is either a `Date.new()` struct
    or a string in the ISO 8601 format.
  * `opts` - Same options as `current_rates/1`.

  """
  @spec get_historic_rate(maybe_date(), keyword) ::
          {:ok, [rate()]} | {:error, term}
  def get_historic_rate(date, opts \\ [])

  def get_historic_rate(date, opts) when is_binary(date) or is_tuple(date) do
    case parse_date(date) do
      {:ok, date} -> get_historic_rate(date, opts)
      {:error, :invalid_date} -> raise Forex.DateError, "Invalid date format"
    end
  end

  def get_historic_rate(%Date{calendar: Calendar.ISO} = date, opts) when is_list(opts) do
    case historic_rates(opts) do
      {:ok, entries} ->
        case find_historic_rate_date(entries, date) do
          nil -> {:error, {Forex.DateError, "Rate not found for date: #{Date.to_iso8601(date)}"}}
          entry -> {:ok, entry.rates}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_historic_rate_date(entries, date) do
    Enum.find(entries, fn
      %{date: %Date{} = d} -> Date.compare(date, d) == :eq
      _ -> false
    end)
  end

  @doc """
  Same as `get_historic_rate/2`, but raises an error if the request fails.
  """
  @spec get_historic_rate!(maybe_date(), keyword) :: [rate()]
  def get_historic_rate!(date, opts \\ [])

  def get_historic_rate!(date, opts) when is_binary(date) or is_tuple(date) do
    case parse_date(date) do
      {:ok, date} -> get_historic_rate!(date, opts)
      {:error, :invalid_date} -> raise Forex.DateError, "Invalid date format"
    end
  end

  def get_historic_rate!(%Date{calendar: Calendar.ISO} = date, opts) when is_list(opts) do
    case get_historic_rate(date, opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise Forex.FeedError, reason
    end
  end

  @doc """
  Get exchange rates between two dates from the historic exchange rates feed.

  Returns a list of exchange rates for each working day between the start and end date.

  ## Arguments

  * `start_date` - Start date (Date, ISO 8601 string, or {year, month, day} tuple)
  * `end_date` - End date (Date, ISO 8601 string, or {year, month, day} tuple)
  * `opts` - Same options as `current_rates/1`

  ## Return Value

  Returns `{:ok, [%{date: Date.t(), base: atom(), rates: map()}]}` where each list item
  represents rates for one day.

  ## Examples

  ```elixir
  iex> Forex.get_historic_rates_between("2023-01-01", "2023-01-05")
  {:ok, [
    %{date: ~D[2023-01-02], base: :eur, rates: %{usd: Decimal.new("1.0678", ...}},
    %{date: ~D[2023-01-03], base: :eur, rates: %{usd: Decimal.new("1.0545", ...}},
    %{date: ~D[2023-01-04], base: :eur, rates: %{usd: Decimal.new("1.0599", ...}},
    %{date: ~D[2023-01-05], base: :eur, rates: %{usd: Decimal.new("1.0556", ...}}
  ]}
  ```
  """
  @spec get_historic_rates_between(maybe_date(), maybe_date(), keyword) ::
          {:ok, [rate()]} | {:error, term}
  def get_historic_rates_between(start_date, end_date, opts \\ [])

  def get_historic_rates_between(start_date, end_date, opts)
      when is_binary(start_date) and is_binary(end_date) do
    with {:ok, start_date} <- parse_date(start_date),
         {:ok, end_date} <- parse_date(end_date) do
      get_historic_rates_between(start_date, end_date, opts)
    else
      {:error, _} -> {:error}
    end
  end

  def get_historic_rates_between(
        %Date{calendar: Calendar.ISO} = start_date,
        %Date{calendar: Calendar.ISO} = end_date,
        opts
      )
      when is_list(opts) do
    case historic_rates(opts) do
      {:ok, entries} ->
        entries_range =
          Enum.filter(entries, fn
            %{date: %Date{} = date} ->
              Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt

            _ ->
              false
          end)

        {:ok, entries_range}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `get_historic_rates_between/3`, but raises an error if the request fails.
  """
  @spec get_historic_rates_between!(maybe_date(), maybe_date(), keyword) :: [rate()]
  def get_historic_rates_between!(start_date, end_date, opts \\ [])

  def get_historic_rates_between!(start_date, end_date, opts)
      when is_binary(start_date) and is_binary(end_date) do
    with {:ok, start_date} <- parse_date(start_date),
         {:ok, end_date} <- parse_date(end_date) do
      get_historic_rates_between!(start_date, end_date, opts)
    else
      {:error, _} -> {:error, {Forex.DateError, "Invalid date format"}}
    end
  end

  def get_historic_rates_between!(
        %Date{calendar: Calendar.ISO} = start_date,
        %Date{calendar: Calendar.ISO} = end_date,
        opts
      )
      when is_list(opts) do
    case get_historic_rates_between(start_date, end_date, opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise Forex.FeedError, reason
    end
  end

  @doc """
  Last updated date of the exchange rates feed.
  Lists the last date the exchange rates were updated from the cache.

  Example:

      iex> Forex.last_updated()
      [
        current_rates: ~U[2024-11-23 18:19:38.974337Z],
        historic_rates: ~U[2024-11-23 18:27:07.391035Z],
        last_ninety_days_rates: ~U[2024-11-23 18:19:39.111818Z],
      ]
  """
  @spec last_updated() :: Keyword.t() | nil
  def last_updated do
    if Forex.Cache.initialized?() do
      Forex.Cache.last_updated()
    else
      nil
    end
  end

  ## Private Functions

  # Default base currency rate
  defp base_currency_rate, do: %{currency: "EUR", rate: "1.00000"}

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  # If not EUR based currency we rebase the rates to the new base currency
  defp map_rates({:error, reason}, _), do: {:error, reason}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)

  defp map_rates(rates, opts) when is_list(rates) do
    [base_currency_rate() | rates]
    |> maybe_filter_currencies(opts.symbols)
    |> Currency.maybe_rebase(opts.base)
    |> case do
      {:ok, rebased_rates} ->
        rebased_rates
        |> Stream.map(fn %{currency: currency, rate: value} ->
          {maybe_atomize_code(currency, opts.keys), rate_value(value, opts)}
        end)
        |> Enum.into(%{})

      error ->
        error
    end
  end

  defp map_rates(_, _), do: []

  # Format the rate value based on the options
  defp rate_value(value, opts) do
    value
    |> format_value(opts.format)
    |> round_value(opts.round)
  end

  # Filter the rates based on the symbols option
  defp maybe_filter_currencies(rates, nil), do: rates
  defp maybe_filter_currencies(rates, []), do: rates

  defp maybe_filter_currencies(rates, symbols) when is_list(symbols) do
    symbols = Enum.map(symbols, &stringify_code/1)

    Enum.filter(rates, fn %{currency: currency} ->
      Enum.member?(symbols, currency)
    end)
  end

  defp maybe_filter_currencies(rates, _), do: rates

  defp maybe_atomize_code(code, :atoms), do: atomize_code(code)
  defp maybe_atomize_code(code, :strings), do: stringify_code(code)
end
