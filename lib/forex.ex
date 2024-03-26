defmodule Forex do
  # TODO: Add option to use cache or not
  # TODO: Add option to set the cache TTL
  # TODO: Check if the cache is setup if not don't use it
  # TODO: Add instructions on how to add the cache to the supervision tree

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

  @options_schema NimbleOptions.new!(
                    format: [type: :atom, default: :decimal],
                    base: [type: :string, default: "EUR"],
                    cache: [
                      type: :boolean,
                      default: Application.compile_env(:forex, :use_cache, false)
                    ]
                  )

  alias Forex.Cache
  alias Forex.Currency
  alias Forex.Feed

  @doc false
  defguard is_currency_code(currency_code)
           when is_atom(currency_code) or is_binary(currency_code)

  ## Currencies

  def available_currencies, do: Currency.all() |> Map.keys()

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
    opts = NimbleOptions.validate!(opts, @options_schema)

    with rates <- fetch_current_rates(opts) do
      rates =
        rates
        |> map_rates(opts)
        |> rebase(opts)

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
    opts = NimbleOptions.validate!(opts, @options_schema)

    with rates <- fetch_current_rates(opts) do
      rates
      |> map_rates(opts)
      |> rebase(opts)
    else
      {:error, reason} -> raise reason
    end
  end

  defp fetch_current_rates(opts) do
    if Keyword.get(opts, :cache),
      do: Cache.resolve(:current, &Feed.current_rates/0),
      else: Feed.current_rates()
  end

  ## Private Functions

  # Map the rates response to the format %{currency_code() => Decimal.t()}
  defp map_rates({:ok, rates}, opts), do: map_rates(rates, opts)
  defp map_rates({:error, reason}, _), do: {:error, reason}

  defp map_rates(rates, opts) when is_list(rates) do
    format = Keyword.get(opts, :format)

    Enum.map(rates, fn %{currency: currency, rate: value} ->
      {currency, format_value(value, format)}
    end)
    |> Enum.into(%{})
  end

  defp rebase(rates, opts) do
    format = Keyword.get(opts, :format)
    base_currency = Keyword.get(opts, :base)

    new_base_rate =
      case Map.get(rates, base_currency) do
        nil -> nil
        rate -> Decimal.new(rate)
      end

    cond do
      base_currency == "EUR" ->
        Map.put(rates, "EUR", format_value(1, format))

      new_base_rate == nil ->
        {:error, "Base currency not found in the available currency rates"}

      true ->
        rates
        |> Enum.map(fn {currency, rate_value} ->
          {currency, convert(rate_value, new_base_rate, format)}
        end)
        |> Map.new()
        |> Map.put("EUR", Decimal.div(1, new_base_rate) |> format_value(format))
        |> Map.put(base_currency, format_value(1, format))
    end
  end

  defp convert(%Decimal{} = currency_value, new_base_value, :decimal) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 6})
    Decimal.div(currency_value, new_base_value)
  end

  defp convert(currency_value, new_base_value, :string) when is_binary(currency_value) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 6})
    Decimal.div(Decimal.new(currency_value), new_base_value) |> Decimal.to_string()
  end

  # Format the rate value based on the `format` option
  defp format_value(value, :string) when is_binary(value), do: value
  defp format_value(value, :decimal) when is_binary(value), do: Decimal.new(value)
  defp format_value(value, :string) when is_number(value), do: to_string(value)
  defp format_value(value, :decimal) when is_number(value), do: Decimal.new(value)
  defp format_value(%Decimal{} = value, :string), do: Decimal.to_string(value)
  defp format_value(%Decimal{} = value, :decimal), do: value
end
