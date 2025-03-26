# Forex

[![hex.pm badge](https://img.shields.io/hexpm/v/forex?style=for-the-badge&labelColor=000)](https://hex.pm/packages/forex)
[![Documentation badge](https://img.shields.io/badge/Docs-3B82F6?style=for-the-badge&labelColor=000)][DOCS]
[![CI badge](https://img.shields.io/github/actions/workflow/status/greven/forex/ci.yml?style=for-the-badge&labelColor=000)](https://github.com/greven/forex/blob/main/.github/workflows/ci.yml)
[![License badge](https://img.shields.io/hexpm/l/forex?style=for-the-badge&labelColor=000)](LICENSE)

<!-- MDOC !-->

`Forex` is a simple Elixir library that serves as a wrapper to the
foreign exchange reference rates provided by the European Central Bank.

> ### ECB Exchange Rates Important Notice
>
> The reference rates are usually updated at **around 16:00 CET** every working day, except on
> [TARGET closing days](https://www.ecb.europa.eu/ecb/contacts/working-hours/html/index.en.html).
>
> They are based on the daily concertation procedure between central banks across Europe, which normally takes place around 14:10 CET.
> The reference rates are published for **information purposes only**. Using the rates for transaction purposes is **strongly discouraged**.
>
> _Source: [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html)_

## Motivation

Even though there are other libraries in the Elixir ecosystem that provide
similar functionality (example: `ex_money`), `Forex` was created with the intent
of providing access to currency exchange rates for projects that want to self-host
the data and not rely on third-party paid services in a simple and straightforward
manner. No API keys, no authentication, no rate limits, just a simple Elixir library
that fetches the data from the European Central Bank and caches it for later use.

If you need a more advanced library that provides additional features and allows you
to fetch exchange rates from multiple sources, you should check out
the excellent [money](https://github.com/kipcole9/money).

## Configuration

### Supervision

By default, `Forex` starts with your application which in turn starts the `Forex.Supervisor`. If you
don't want to start the `Forex` supervision tree by default, you can pass the `runtime: false` option
to the `forex` dependency in your `mix.exs` file:

```elixir
def deps do
  [
    {:forex, "~> 0.2.2", runtime: false}
  ]
end
```

The `Forex` supervision tree is responsible for fetching the exchange rates from the European Central Bank
and caching them for later use. If you want to start the `Forex.Fetcher` manually, you can do so by calling
the `Forex.Fetcher.Supervisor.start_link/1` function in your application supervision tree.

### HTTP Client

By default, `Forex` uses the `Req` HTTP client in `Forex.Feed.API.HTTP` to fetch the exchange rates from
the European Central Bank. To use a different HTTP client, define your own implementation of
the `Forex.Feed.API` behaviour and pass it to the `Forex` module in your `config.exs` file:

```elixir
config :forex, feed_api: MyApp.Forex.API
```


## Usage

By default the `base` currency is the Euro (EUR), the same as the European Central Bank,
but you can change the base currency by passing the `base` option (for other options see the
[Options](#options) section) to the relevant functions.

To fetch the latest exchange rates, you can use the `latest_rates/1` function:

```elixir
iex> Forex.latest_rates()
{:ok,
  %Forex{
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
    %Forex{date: ~D[2025-03-12], base: :eur, rates: %{usd: Decimal.new("1.1234"), ...}},
    ...
  ]}
```

To fetch the historic exchange rates (for any working day since 4 January 1999),
you can use the `historic_rates/1` function:

```elixir
iex> Forex.historic_rates()
{:ok,
  [
    %Forex{date: ~D[2025-03-12], base: :eur, rates: %{usd: Decimal.new("1.1234"), ...}},
    ...
  ]}
```

To fetch the exchange rates for a specific date, you can use the `get_historic_rate/2` function:

```elixir
iex> Forex.get_historic_rate(~D[2025-02-25])
{:ok,
  [
    %Forex{date: ~D[2025-03-12], base: :eur, rates: %{usd: Decimal.new("1.1234"), ...}},
    ...
  ]}
```

To fetch the exchange rates between two dates, you can use the `get_historic_rates_between/3` function:

```elixir
iex> Forex.get_historic_rates_between(~D[2025-02-25], ~D[2025-02-28])

{:ok,
  [
    %Forex{date: ~D[2025-03-12], base: :eur, rates: %{usd: Decimal.new("1.1234"), ...}},
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

<!-- MDOC !-->

## Mix Tasks

`Forex` provides a mix task to fetch exchange rates from the European Central Bank and export them to
a `json` file. There are three mix tasks available:

- `mix forex.export.latest` - fetches the latest exchange rates from the European Central Bank and exports them to a `json` file.
- `mix forex.export.ninety` - fetches the last ninety days exchange rates from the European Central Bank and exports them to a `json` file.
- `mix forex.export.historic` - fetches the historic exchange rates from the European Central Bank and exports them to a `json` file.

Check the mix tasks documentation for more information on how to use them.

### Note

The mix tasks `json` encoder uses the Elixir 1.18 `JSON` module by default. If you are using an older version of Elixir,
you can use any other JSON library (for example [Jason](https://hex.pm/packages/jason)) as long as the library
implements the `encode_to_iodata!/2` function. This can be configured by setting
the `json_library` option in the `config.exs` file of your project:

```elixir
config :forex, json_library: Jason
```


## Installation

The package can be installed by adding `forex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:forex, "~> 0.2.2"}
  ]
end
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

[DOCS]: https://hexdocs.pm/forex
