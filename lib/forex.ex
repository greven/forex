defmodule Forex do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
             |> String.replace("### Usage Information", "### Usage Information {: .info}")

  import Forex.Support
  import Forex.Options, only: [rates_options: 1]

  alias Forex.Options
  alias Forex.Currency
  alias Forex.Fetcher

  defstruct [:base, :date, :rates]

  @typedoc """
  A currency rate, represented as a map with the currency code as
  the key and the rate amount as the value.
  """
  @type rate :: %{Currency.code() => Currency.output_amount()}

  @typedoc """
  A Forex struct, representing the exchange rates for a given date.
  """
  @type t :: %__MODULE__{
          base: Currency.code(),
          date: Date.t(),
          rates: rate()
        }

  # A date that can be either a string in the ISO 8601 format, a Date struct
  # or a tuple with the date components in the format `{year, month, day}`.
  @typep maybe_date :: String.t() | tuple() | Date.t()

  @base_currency_rate %{currency: "EUR", rate: "1.00000"}

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
    Application.get_env(:forex, :json_library, JSON)
  end

  ## Currencies

  @doc """
  Return a list of all available currencies ISO 4217 codes.
  """
  @spec available_currencies(keys :: :atoms | :strings) :: [Currency.code()]
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
  @spec list_currencies(keys :: :atoms | :strings) :: %{Currency.code() => Currency.t()}
  def list_currencies(keys \\ :atoms)
  def list_currencies(:atoms), do: Currency.available(:atoms)
  def list_currencies(:strings), do: Currency.available(:strings)

  @doc """
  Return a list of all available currencies in the format
  `%{currency_code() => currency_name()}`.
  Useful for input forms, selects, etc.
  """
  @spec currency_options(keys :: :atoms | :strings) :: [{String.t(), Currency.code()}]
  def currency_options(keys \\ :atoms)

  def currency_options(:atoms) do
    list_currencies(:atoms)
    |> Enum.map(fn {code, currency} ->
      {currency.name, code}
    end)
    |> Enum.sort()
  end

  def currency_options(:strings) do
    list_currencies(:strings)
    |> Enum.map(fn {code, currency} ->
      {currency.name, code}
    end)
    |> Enum.sort()
  end

  @doc """
  Get the currency information for the given ISO code.
  """
  @spec get_currency(Currency.code()) :: {:ok, Currency.t()} | {:error, term}
  def get_currency(currency_code),
    do: Currency.get(currency_code)

  @doc """
  Get the currency information for the given ISO code.
  Like `get_currency/1`, but raises an error if the currency is not found.
  """
  @spec get_currency!(Currency.code()) :: Currency.t()
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
  @spec exchange(
          amount :: Currency.input_amount(),
          from :: Currency.code(),
          to :: Currency.code(),
          opts :: [Options.currency_option()]
        ) ::
          {:ok, Currency.output_amount()} | {:error, term}
  def exchange(amount, from, to, opts \\ []),
    do: Currency.exchange(amount, from, to, opts)

  @doc """
  Same as `exchange/3`, but raises an error if the request fails.
  """
  @spec exchange!(
          amount :: Currency.input_amount(),
          from :: Currency.code(),
          to :: Currency.code(),
          opts :: [Options.currency_option()]
        ) :: Currency.output_amount()
  def exchange!(amount, from, to, opts \\ []),
    do: Currency.exchange!(amount, from, to, opts)

  ## Exchange Rates

  @doc """
  Fetch the latest exchange rates from the European Central Bank (ECB).

  ## Options
  #{NimbleOptions.docs(Forex.Options.rates_schema())}

  ## Examples

  ```elixir
  {:ok, %{base: :eur, date: ~D[2025-03-12], rates: %{usd: Decimal.new("1.1234"), jpy: Decimal.new("120.1234"), ...}}}
  ```
  """
  @spec latest_rates(opts :: [Options.rates_option()]) :: {:ok, t()} | {:error, term}
  def latest_rates(opts \\ []) when is_list(opts) do
    opts = rates_options(opts)
    base = Keyword.get(opts, :base)

    case Fetcher.get(:latest_rates, use_cache: opts[:use_cache], feed_fn: opts[:feed_fn]) do
      {:ok, entries} ->
        result =
          Enum.map(entries, fn %{time: datetime, rates: rates} ->
            %{
              base: base,
              date: map_date(datetime),
              rates: map_rates(rates, opts)
            }
          end)
          |> List.first()

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `latest_rates/1`, but raises an error if the request fails.
  """
  @spec latest_rates!(opts :: [Options.rates_option()]) :: t()
  def latest_rates!(opts \\ []) when is_list(opts) do
    case latest_rates(opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Fetch the exchange rates for the last ninety days
  from the European Central Bank (ECB).

  Note that rates are only available on working days.

  ## Options
  #{NimbleOptions.docs(Forex.Options.rates_schema())}
  """
  @spec last_ninety_days_rates(opts :: [Options.rates_option()]) ::
          {:ok, [t()]} | {:error, term}
  def last_ninety_days_rates(opts \\ []) when is_list(opts) do
    opts = rates_options(opts)
    base = Keyword.get(opts, :base)

    case Fetcher.get(:last_ninety_days_rates,
           use_cache: opts[:use_cache],
           feed_fn: opts[:feed_fn]
         ) do
      {:ok, entries} ->
        results =
          entries
          |> Stream.map(fn %{time: datetime, rates: rates} ->
            %{
              base: base,
              date: map_date(datetime),
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
  Same as `last_ninety_days_rates/1`, but raises an error if the request fails.
  """
  @spec last_ninety_days_rates!(opts :: [Options.rates_option()]) :: [t()]
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

   ## Options
   #{NimbleOptions.docs(Forex.Options.rates_schema())}
  """
  @spec historic_rates(opts :: [Options.rates_option()]) :: {:ok, [t()]} | {:error, term}
  def historic_rates(opts \\ []) when is_list(opts) do
    opts = rates_options(opts)
    base = Keyword.get(opts, :base)

    case Fetcher.get(:historic_rates, use_cache: opts[:use_cache], feed_fn: opts[:feed_fn]) do
      {:ok, entries} ->
        results =
          entries
          |> Stream.map(fn %{time: datetime, rates: rates} ->
            %{
              base: base,
              date: map_date(datetime),
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
  @spec historic_rates!(opts :: [Options.rates_option()]) :: [t()]
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

  ## Options
  #{NimbleOptions.docs(Forex.Options.rates_schema())}
  """
  @spec get_historic_rate(maybe_date(), opts :: [Options.rates_option()]) ::
          {:ok, rate()} | {:error, term}
  def get_historic_rate(date, opts \\ [])

  def get_historic_rate(date, opts) when is_binary(date) or is_tuple(date) do
    case parse_date(date) do
      {:ok, date} -> get_historic_rate(date, opts)
      {:error, :invalid_date} -> {:error, :invalid_date}
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

  @spec find_historic_rate_date(entries :: [t()], date :: Date.t()) :: t() | nil
  defp find_historic_rate_date(entries, date) when is_list(entries) do
    Enum.find(entries, fn
      %{date: %Date{} = d} -> Date.compare(date, d) == :eq
      _ -> nil
    end)
  end

  @doc """
  Same as `get_historic_rate/2`, but raises an error if the request fails.
  """
  @spec get_historic_rate!(maybe_date(), opts :: [Options.rates_option()]) :: rate()
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

  ## Options
  #{NimbleOptions.docs(Forex.Options.rates_schema())}

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
  @spec get_historic_rates_between(maybe_date(), maybe_date(), opts :: [Options.rates_option()]) ::
          {:ok, [t()]} | {:error, term}
  def get_historic_rates_between(start_date, end_date, opts \\ [])

  def get_historic_rates_between(start_date, end_date, opts)
      when is_binary(start_date) and is_binary(end_date) do
    with {:ok, start_date} <- parse_date(start_date),
         {:ok, end_date} <- parse_date(end_date) do
      get_historic_rates_between(start_date, end_date, opts)
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
    end
  end

  @doc """
  Same as `get_historic_rates_between/3`, but raises an error if the request fails.
  """
  @spec get_historic_rates_between!(maybe_date(), maybe_date(), opts :: [Options.rates_option()]) ::
          [t()]
  def get_historic_rates_between!(start_date, end_date, opts \\ [])

  def get_historic_rates_between!(start_date, end_date, opts)
      when is_binary(start_date) and is_binary(end_date) do
    with {:ok, start_date} <- parse_date(start_date),
         {:ok, end_date} <- parse_date(end_date) do
      get_historic_rates_between!(start_date, end_date, opts)
    else
      {:error, _} -> raise Forex.DateError, "Invalid date format"
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
        latest_rates: ~U[2024-11-23 18:19:38.974337Z],
        historic_rates: ~U[2024-11-23 18:27:07.391035Z],
        last_ninety_days_rates: ~U[2024-11-23 18:19:39.111818Z],
      ]
  """
  @spec last_updated() ::
          [
            latest_rates: DateTime.t(),
            historic_rates: DateTime.t(),
            last_ninety_days_rates: DateTime.t()
          ]
          | nil
  def last_updated do
    if Forex.Cache.initialized?() do
      Forex.Cache.last_updated()
    else
      nil
    end
  end

  ## Private Functions

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  # If not EUR based currency we rebase the rates to the new base currency
  defp map_rates({:error, reason}, _), do: {:error, reason}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)

  defp map_rates(rates, opts) when is_list(rates) do
    [@base_currency_rate | rates]
    |> maybe_filter_currencies(opts[:symbols])
    |> Currency.maybe_rebase(opts[:base])
    |> case do
      {:ok, rebased_rates} ->
        rebased_rates
        |> Stream.map(fn %{currency: currency, rate: value} ->
          {maybe_atomize_code(currency, opts[:keys]), rate_value(value, opts)}
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
    |> format_value(opts[:format])
    |> round_value(opts[:round])
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
