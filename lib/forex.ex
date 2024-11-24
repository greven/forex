defmodule Forex do
  @moduledoc """
  `Forex` is a simple Elixir library that serves as a wrapper to the
  foreign exchange reference rates provided by the European Central Bank.

  ## Motivation

  Even though there are other libraries in the Elixir ecosystem that provide
  similar functionality (example: `ex_money`), `Forex` was created with the intent
  of providing access to currency exchange rates, for projects that want to self-host
  the data and not rely on third-party paid services in a simple and straightforward
  manner.

  The exchange rates are updated daily around 16:00 CET.

  ## Options

  * `:base` - The base currency to convert the rates to. The default currency base is `:EUR`.

  * `:format` - The format of the rate value. Supported values are `:decimal` and `:string`.
    The default is `:decimal`.

  * `:round` - The number of decimal places to round the rate value to. The default is `4`.

  * `:keys` - The format of the keys in the rate map. Supported values are `:strings` and `:atoms`.
    The default is `:atoms`.

  * `:use_cache` - A boolean value to enable or disable the cache. To enable the cache check the
    usage section docs for detailed instructions. The default is `false`.

  * `:feed_mfa` - An `mfa` tuple that can be used to fetch the exchange rates from a custom feed.
    This option is mostly used for testing purposes.

  ## Usage

  By default the `base` currency is the Euro (EUR), the same as the European Central Bank,
  but you change the base currency by passing the `base` option to the relevant functions.

  ```elixir
  iex> Forex.current_rates()
  {:ok,
    %{date: ~U[2024-11-23 18:19:38.974337Z],
      rates: %{
        usd: Decimal.new("1.1234"),
        jpy: Decimal.new("120.1234"),
        ...
        zar: Decimal.new("24.1442")
      }}
    }
  ```
  """

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

  @typedoc """
  A date that can be either a string in the ISO 8601 format, a Date struct
  or a tuple with the date components in the format `{year, month, day}`.
  """
  @type maybe_date :: String.t() | tuple() | Date.t()

  import Forex.Helper

  alias Forex.Fetcher
  alias Forex.Currency

  ## Options

  defp options_schema do
    NimbleOptions.new!(
      base: [type: {:in, currency_schema_options()}, default: :eur],
      format: [type: {:in, ~w(decimal string)a}, default: :decimal],
      keys: [type: {:in, ~w(strings atoms)a}, default: :atoms],
      round: [type: {:or, [:integer, nil]}, default: 5],
      use_cache: [type: :boolean, default: true],
      feed_fn: [type: :mfa, default: nil]
    )
  end

  def options(opts \\ []) do
    NimbleOptions.validate!(opts, options_schema())
    |> Enum.into(%{})
  end

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
  {:ok, 89.2857}
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
  Fetch the latest exchange rates from the European Central Bank (ECB),
  and return the rates in the format `%{currency_code() => Decimal.t()}`.

  ## Arguments

  * `opts` - A keyword list of options. The following options are supported:
    * `:format` - The format of the rate value. The default is `:decimal`. Supported values are `:decimal` and `:string`.
    * `:base` - The base currency to convert the rates to. The default is currency base is `EUR`.

  ## Examples

  ```elixir
  iex> Forex.current_rates()
  {:ok,
    %{
      aud: Decimal.new("1.6580"),
      bgn: Decimal.new("1.9558"),
      eur: Decimal.new("1.00000"),
    ...
  }}
  ```

  ```elixir
  iex> Forex.current_rates(format: :string)
  {:ok,
    %{
      aud: "1.6580",
      bgn: "1.9558",
    ...
  }}
  ```

  ```elixir
  iex> Forex.current_rates(base: :usd)
  {:ok,
    %{
      aud: Decimal.new("1.53023"),
      bgn: Decimal.new("1.80508"),
      eur: Decimal.new("0.922935"),
      usd: Decimal.new("1.00000"),
    ...
  }}
  ```
  """
  @spec current_rates(keyword) :: {:ok, rate()} | {:error, term}
  def current_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    with {:ok, entries} <-
           Fetcher.get(:current_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      entries =
        Enum.map(entries, fn %{time: datetime, rates: rates} ->
          %{date: map_date(datetime), rates: map_rates(rates, options(opts))}
        end)
        |> List.first()

      {:ok, entries}
    else
      {:error, reason} -> {:error, reason}
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

    with {:ok, entries} <-
           Fetcher.get(:last_ninety_days_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      entries =
        entries
        |> Stream.map(fn %{time: datetime, rates: rates} ->
          %{date: map_date(datetime), rates: map_rates(rates, options(opts))}
        end)
        |> Enum.filter(fn %{date: date} -> date != nil end)

      {:ok, entries}
    else
      {:error, reason} -> {:error, reason}
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

  ## Arguments

  Same options as `current_rates/1`.
  """
  @spec historic_rates(keyword) :: {:ok, [rate()]} | {:error, term}
  def historic_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    with {:ok, entries} <-
           Fetcher.get(:historic_rates, use_cache: opts.use_cache, feed_fn: opts.feed_fn) do
      entries =
        entries
        |> Stream.map(fn %{time: datetime, rates: rates} ->
          %{date: map_date(datetime), rates: map_rates(rates, opts)}
        end)
        |> Enum.filter(fn %{date: date} -> date != nil end)

      {:ok, entries}
    else
      {:error, reason} -> {:error, reason}
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
  It returns either an ´{:ok, rate()}` if the rate was successfully
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
      {:error, error} -> raise error
    end
  end

  def get_historic_rate(%Date{calendar: Calendar.ISO} = date, opts) when is_list(opts) do
    case historic_rates(opts) do
      {:ok, entries} ->
        case Enum.find(entries, fn
               %{date: %Date{} = d} -> Date.compare(date, d) == :eq
               _ -> false
             end) do
          nil -> {:error, {Forex.DateError, "Rate not found for date: #{Date.to_iso8601(date)}"}}
          entry -> {:ok, entry.rates}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `get_historic_rate/2`, but raises an error if the request fails.
  """
  @spec get_historic_rate!(maybe_date(), keyword) :: [rate()]
  def get_historic_rate!(date, opts \\ [])

  def get_historic_rate!(date, opts) when is_binary(date) or is_tuple(date) do
    case parse_date(date) do
      {:ok, date} -> get_historic_rate!(date, opts)
      {:error, reason} -> raise Forex.DateError, reason
    end
  end

  def get_historic_rate!(%Date{calendar: Calendar.ISO} = date, opts) when is_list(opts) do
    case get_historic_rate(date, opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise Forex.FeedError, reason
    end
  end

  @doc """
  Get the exchange rates between two dates from the historic exchange rates feed.
  It returns a list of exchange rates for each working day between the the start
  and end date.

  ## Arguments

  * `date` - The date to get the rate for. `date` is either a `Date.new()` struct
    or a string in the ISO 8601 format.
  * `opts` - Same options as `current_rates/1`.
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
  def base_currency_rate, do: %{currency: "EUR", rate: "1.00000"}

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  # If not EUR based currency we rebase the rates to the new base currency
  defp map_rates({:error, reason}, _), do: {:error, reason}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)

  defp map_rates(rates, opts) when is_list(rates) do
    [base_currency_rate() | rates]
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

  defp maybe_atomize_code(code, :atoms), do: atomize_code(code)
  defp maybe_atomize_code(code, :strings), do: stringify_code(code)
end
