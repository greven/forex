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

  * `:base` - The base currency to convert the rates to. The default currency base is `EUR`.
  * `:format` - The format of the rate value. Supported values are `:decimal` and `:string`. The default is `:decimal`.
  * `:round` - The number of decimal places to round the rate value to. The default is `4`.
  * `:use_cache` - A boolean value to enable or disable the cache. To enable the cache check the usage section docs for detailed instructions. The default is `false`.

  ## Usage

  By default the `base` currency is the Euro (EUR), the same as the European Central Bank,
  but you change the base currency by passing the `base` option to the relevant functions.

  ```elixir
  iex> Forex.current_rates()
  {:ok,
   %{
     "USD" => Decimal.new("1.1234"),
     "JPY" => Decimal.new("120.1234"),
     ...
     "ZAR" => Decimal.new("24.1442")
   }}
  ```
  """

  @type currency_code :: String.t() | atom()
  @type rate :: %{currency_code() => Decimal.t() | String.t()}
  @type maybe_date :: String.t() | tuple() | Date.t()

  import Forex.Helper

  alias Forex.Fetcher
  alias Forex.Currency

  ## Options

  defp options_schema do
    NimbleOptions.new!(
      base: [type: :string, default: "EUR"],
      format: [type: :atom, default: :decimal],
      round: [type: {:or, [:integer, nil]}, default: 4],
      use_cache: [type: :boolean, default: true]
    )
  end

  def options(opts \\ []) do
    NimbleOptions.validate!(opts, options_schema())
  end

  ## Currencies

  @doc """
  Return a list of all available currencies ISO 4217 codes.
  """
  def available_currencies,
    do: Currency.all() |> Map.keys()

  @doc """
  Return a list of all available currencies.
  """
  def list_currencies,
    do: Currency.all()

  @doc """
  Return a list of all available currencies in the format
  `%{currency_code() => currency_name()}`.
  Useful for input forms, selects, etc.
  """
  def currency_options do
    Currency.all()
    |> Enum.map(fn {code, currency} ->
      {currency.name, code}
    end)
  end

  @doc """
  Get the currency information for the given ISO code.
  """
  def get_currency(currency_code),
    do: Currency.get(currency_code)

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
      "AUD" => Decimal.new("1.6580"),
      "BGN" => Decimal.new("1.9558"),
    ...
  }}
  ```

  ```elixir
  iex> Forex.current_rates(format: :string)
  {:ok,
    %{
      "AUD" => "1.6580",
      "BGN" => "1.9558",
    ...
  }}
  ```

  ```elixir
  iex> Forex.current_rates(base: "USD")
  {:ok,
    %{
      "AUD" => Decimal.new("1.53023"),
      "BGN" => Decimal.new("1.80508"),
      "EUR" => Decimal.new("0.922935"),
      "USD" => Decimal.new("1"),
    ...
  }}
  ```
  """
  @spec current_rates(keyword) :: {:ok, rate()} | {:error, term}
  def current_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    with {:ok, rates} <- Fetcher.current_rates(opts[:use_cache]) do
      {:ok, map_rates(rates, opts)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `current_rates/1`, but raises an error if the request fails.
  """
  @spec current_rates!(keyword) :: rate()
  def current_rates!(opts \\ []) when is_list(opts) do
    opts = options(opts)

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

    with {:ok, entries} <- Fetcher.last_ninety_days_rates(opts[:use_cache]) do
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
  Same as `last_ninety_days_rates/1`, but raises an error if the request fails.
  """
  @spec last_ninety_days_rates!(keyword) :: [rate()]
  def last_ninety_days_rates!(opts \\ []) when is_list(opts) do
    opts = options(opts)

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

    with {:ok, entries} <- Fetcher.historic_rates(opts[:use_cache]) do
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
    opts = options(opts)

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
          nil -> {:error, "Rate not found for date: #{Date.to_iso8601(date)}"}
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
      {:error, error} -> raise error
    end
  end

  def get_historic_rate!(%Date{calendar: Calendar.ISO} = date, opts) when is_list(opts) do
    case get_historic_rate(date, opts) do
      {:ok, rates} -> rates
      {:error, reason} -> raise reason
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
      {:error, _} -> {:error, "Invalid date format"}
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
      {:error, _} -> {:error, "Invalid date format"}
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
      {:error, reason} -> raise reason
    end
  end

  ## Private Functions

  # Default base currency rate
  def base_currency_rate do
    %{currency: "EUR", rate: "1.0000"}
  end

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  # If not EUR based currency we rebase the rates to the new base currency
  defp map_rates({:error, reason}, _), do: {:error, reason}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)

  defp map_rates(rates, opts) when is_list(rates) do
    opts = Map.new(opts)

    [base_currency_rate() | rates]
    |> Currency.maybe_rebase(opts.base)
    |> case do
      {:ok, rebased_rates} ->
        rebased_rates
        |> Stream.map(fn %{currency: currency, rate: value} ->
          {currency, rate_value(value, opts)}
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
end
