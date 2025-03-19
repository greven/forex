# Forex

`Forex` is a simple Elixir library that serves as a wrapper to the
  foreign exchange reference rates provided by the European Central Bank.

  > [!NOTE]
  > ### From the [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html)
  >
  > The reference rates are usually updated at around **16:00 CET** every working day, except on
  > [TARGET closing days](https://www.ecb.europa.eu/ecb/contacts/working-hours/html/index.en.html).
  >
  > They are based on the daily concertation procedure between central banks across Europe,
  > which normally takes place around 14:10 CET. The reference rates are published for
  > information purposes only. Using the rates for transaction
  > purposes is _strongly discouraged_.

  ## Motivation

Even though there are other libraries in the Elixir ecosystem that provide
  similar functionality (example: `ex_money`), `Forex` was created with the intent
  of providing access to currency exchange rates for projects that want to self-host
  the data and not rely on third-party paid services in a simple and straightforward
  manner. No API keys, no authentication, no rate limits, just a simple Elixir library
  that fetches the data from the European Central Bank and caches it for later use.

  ## Options

  * `:base` - The base currency to convert the rates to. The default currency base is `:eur`.

  * `:format` - The format of the rate value. Supported values are `:decimal` and `:string`.
    The default is `:decimal`.

  * `:round` - The number of decimal places to round the rate value to. The default is `5`.

  * `:symbols` - A list of currency codes (atoms or strings) to filter the rates by.
    The default is `nil`, which means all available currencies will be returned.

  * `:keys` - The format of the keys in the rate map. Supported values are `:strings` and `:atoms`.
    The default is `:atoms`.

  * `:use_cache` - A boolean value to enable or disable the cache. To enable the cache check the
    usage section docs for detailed instructions. The default is `true`.

  * `:feed_fn` - An `mfa` tuple that can be used to fetch the exchange rates from a custom feed.
    This option is mostly used for testing purposes. The default is `nil`, which means the
    default feed will be used.

  ## Usage

  By default the `base` currency is the Euro (EUR), the same as the European Central Bank,
  but you change the base currency by passing the `base` option to the relevant functions.

  To fetch the latest exchange rates, you can use the `current_rates/1` function:

  ```elixir
  iex> Forex.current_rates()
  {:ok,
    %{
      base: :eur,
      date: ~D[2025-03-12],
      rates: %{
        usd: Decimal.new("1.1234"),
        jpy: Decimal.new("120.1234"),
        ...
        zar: Decimal.new("24.1442")
      }}
    }
  ```

  To fetch the exchange rates for the last ninety days, you can use the `last_ninety_days_rates/1` function:

  ```elixir
  iex> Forex.last_ninety_days_rates()
  {:ok,
    [
      %{
        date: ~D[2025-03-12],
        base: :eur,
        rates: %{
          usd: Decimal.new("1.1234"),
          jpy: Decimal.new("120.1234"),
          ...
          zar: Decimal.new("24.1442")
        }
      },
      ...
    ]}
  ```

  To fetch the historic exchange rates (for any working day since 4 January 1999),
  you can use the `historic_rates/1` function:

  ```elixir
  iex> Forex.historic_rates()
  {:ok,
    [
      %{
        date: ~D[2025-03-12],
        base: :eur,
        rates: %{
          usd: Decimal.new("1.1234"),
          jpy: Decimal.new("120.1234"),
          ...
          zar: Decimal.new("24.1442")
        }
      },
      ...
    ]}
  ```

  To fetch the exchange rates for a specific date, you can use the `get_historic_rate/2` function:

  ```elixir
  iex> Forex.get_historic_rate(~D[2025-02-25])
  {:ok,
    [
      %{
        date: ~D[2025-03-12],
        base: :eur,
        rates: %{
          usd: Decimal.new("1.1234"),
          jpy: Decimal.new("120.1234"),
          ...
          zar: Decimal.new("24.1442")
        }
      },
      ...
    ]}
  ```

  To fetch the exchange rates between two dates, you can use the `get_historic_rates_between/3` function:

  ```elixir
  iex> Forex.get_historic_rates_between(~D[2025-02-25], ~D[2025-02-28])

  {:ok,
    [
      %{
        date: ~D[2025-03-12],
        base: :eur,
        rates: %{
          usd: Decimal.new("1.1234"),
          jpy: Decimal.new("120.1234"),
          ...
          zar: Decimal.new("24.1442")
        }
      },
      ...
    ]}
  ```

  To convert an amount from one currency to another, you can use the `exchange/4` function:

  ```elixir
  iex> Forex.exchange(100, "USD", "EUR")
  {:ok, Decimal.new("91.86100")}

  iex>  Forex.exchange(420, :eur, :gbp)
  {:ok, Decimal.new("353.12760")}
  ```

  To list all available currencies from the European Central Bank,
  you can use the `available_currencies/1` function:

  ```elixir
  iex> Forex.available_currencies()
  [:try, :eur, :aud, :bgn, :brl, ...]
  ```


Full documentation can be found at https://hexdocs.pm/forex.

## Installation

The package can be installed by adding `forex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:forex, "~> 0.1.1"}
  ]
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

