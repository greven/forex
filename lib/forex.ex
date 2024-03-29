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

  * `:format` - The format of the rate value. The default is `:decimal`. Supported values are `:decimal` and `:string`.
  * `:base` - The base currency to convert the rates to. The default currency base is `EUR`.
  * `:cache` - A boolean value to enable or disable the cache. The default is `false`. To enable the cache check the usage section docs for detailed instructions.

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

  alias Forex.Fetcher
  alias Forex.Currency
  alias Forex.Helper

  ## Options

  defp options_schema do
    NimbleOptions.new!(
      base: [type: :string, default: "EUR"],
      format: [type: :atom, default: :decimal]
    )
  end

  def options(opts \\ []) do
    NimbleOptions.validate!(opts, options_schema())
  end

  ## Guards

  @doc false
  defguard is_currency_code(currency_code)
           when is_atom(currency_code) or is_binary(currency_code)

  ## Currencies

  @doc """
  Return a list of all available currencies ISO 4217 codes.
  """
  def available_currencies, do: Currency.all() |> Map.keys()

  @doc """
  Return a list of all available currencies.
  """
  def list_currencies, do: Currency.all()

  def get_currency(currency_code) when is_currency_code(currency_code) do
    Currency.get(currency_code)
  end

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

    with {:ok, rates} <- Fetcher.current_rates() do
      rates =
        rates
        |> map_rates(opts)
        |> Currency.rebase(opts)

      {:ok, rates}
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

    with {:ok, rates} <- Fetcher.current_rates() do
      rates
      |> map_rates(opts)
      |> Currency.rebase(opts)
    else
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Fetch the exchange rates for the last ninety days from
  the European Central Bank (ECB).

  ## Arguments

  * `opts` - A keyword list of options. The following options are supported:
    * `:format` - The format of the rate value. The default is `:decimal`. Supported values are `:decimal` and `:string`.
    * `:base` - The base currency to convert the rates to. The default is currency base is `EUR`.
  """
  @spec last_ninety_days_rates(keyword) :: {:ok, [rate()]} | {:error, term}
  def last_ninety_days_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    with {:ok, entries} <- Fetcher.last_ninety_days_rates() do
      entries =
        entries
        |> Enum.map(fn %{time: datetime, rates: rates} ->
          rates =
            rates
            |> map_rates(opts)
            |> Currency.rebase(opts)

          %{date: Helper.parse_date(datetime), rates: rates}
        end)

      {:ok, entries}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetch the historic exchange rates feed from
  the European Central Bank (ECB).

  By default, the historic rates are not automatically fetched when using
  the Fetcher (scheduler) module, since the whole file is returned this avoids excessive memory
  usage when caching the results if not needed. To fetch and cache the historic rates,
  you need to manually call this function.

  ## Arguments

  * `opts` - A keyword list of options. The following options are supported:
    * `:format` - The format of the rate value. The default is `:decimal`. Supported values are `:decimal` and `:string`.
    * `:base` - The base currency to convert the rates to. The default is currency base is `EUR`.
  """
  @spec historic_rates(keyword) :: {:ok, [rate()]} | {:error, term}
  def historic_rates(opts \\ []) when is_list(opts) do
    opts = options(opts)

    with {:ok, entries} <- Fetcher.historic_rates() do
      entries =
        entries
        |> Enum.map(fn %{time: datetime, rates: rates} ->
          rates =
            rates
            |> map_rates(opts)
            |> Currency.rebase(opts)

          %{date: Helper.parse_date(datetime), rates: rates}
        end)

      {:ok, entries}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get a specific date from the historic exchange rates feed.
  It returns either an ´{:ok, rate()}` if the rate was successfully
  retrieved or an `{:error, reasons}` if the rate was not found.

  ## Arguments

  * `date` - The date to get the rate for. `date` is either a `Date.new()` struct
    or a string in the ISO 8601 format.
  * `opts` - A keyword list of options. The following options are supported:
    * `:format` - The format of the rate value. The default is `:decimal`. Supported values are `:decimal` and `:string`.
    * `:base` - The base currency to convert the rates to. The default is currency base is `EUR`.

  """
  def get_historic_rate(date, opts \\ [])

  def get_historic_rate(date, opts) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> get_historic_rate(date, opts)
      _ -> {:error, "Invalid date format: #{date}"}
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

  ## Private Functions

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)
  defp map_rates({:error, reason}, _), do: {:error, reason}

  defp map_rates(rates, opts) when is_list(rates) do
    format = Keyword.get(opts, :format)

    Enum.map(rates, fn %{currency: currency, rate: value} ->
      {currency, Helper.format_value(value, format)}
    end)
    |> Enum.into(%{})
  end
end
