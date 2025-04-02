defmodule Forex.Options do
  @moduledoc """
  Options/configuration module for the Forex.Fetcher.Supervisor and the rates functions
  (`latest_rates/1`, `last_ninety_days_rates/1`, etc.) in the `Forex` module.
  """

  @currency_atoms ~w(
    aud bgn brl cad chf cny czk dkk eur gbp hkd
    huf idr ils inr isk jpy krw mxn myr nok nzd
    php pln ron sek sgd thb try usd zar AUD BGN
    BRL CAD CHF CNY CZK DKK EUR GBP HKD HUF IDR
    ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN
    RON SEK SGD THB TRY USD ZAR)a

  @allowed_codes @currency_atoms ++ Enum.map(@currency_atoms, &to_string/1)

  @options base: [
             type: {:in, @allowed_codes},
             default: :eur,
             doc: "The base currency to convert rates to"
           ],
           format: [
             type: {:in, ~w(decimal string)a},
             default: :decimal,
             doc: "Format of rate values"
           ],
           round: [
             type: {:or, [:integer, nil]},
             default: 5,
             doc: "Decimal places for rounding"
           ],
           keys: [
             type: {:in, ~w(strings atoms)a},
             default: :atoms,
             doc: "Map key format"
           ],
           symbols: [
             type: {:or, [{:list, {:in, @allowed_codes}}, nil]},
             doc: "Currency codes to include"
           ],
           use_cache: [
             type: :boolean,
             default: Application.compile_env(:forex, :use_cache, true),
             doc: "Whether to use cached rates"
           ],
           feed_fn: [
             type: :mfa,
             doc: "Optional custom feed function as `{module, function, args}`"
           ],
           schedular_interval: [
             type: :integer,
             default: Application.compile_env(:forex, :schedular_interval, :timer.hours(12)),
             doc: "Interval for the scheduler to fetch rates"
           ],
           auto_start: [
             type: :boolean,
             default: Application.compile_env(:forex, :auto_start, true),
             doc: "Whether to start the fetcher automatically"
           ]

  ## Forex Module Options

  @rates_schema NimbleOptions.new!(
                  Keyword.take(
                    @options,
                    ~w(base format round keys symbols use_cache feed_fn)a
                  )
                )

  @type rates_option() :: unquote(NimbleOptions.option_typespec(@rates_schema))

  def rates_schema, do: @rates_schema

  @doc """
  Validate and return the options for the Forex module functions.

  Supported options:\n#{NimbleOptions.docs(@rates_schema)}
  """
  @spec rates_options(opts :: keyword()) :: validated_options :: [rates_option()] | map()
  def rates_options(opts \\ []) do
    NimbleOptions.validate!(opts, @rates_schema)
  end

  ## Fetcher Supervisor Module Options

  @fetcher_supervisor_schema NimbleOptions.new!(Keyword.take(@options, ~w(auto_start)a))

  @type fetcher_supervisor_option() ::
          unquote(NimbleOptions.option_typespec(@fetcher_supervisor_schema))

  def fetcher_supervisor_schema, do: @fetcher_supervisor_schema

  @doc """
  Validate and return the options for the Forex.Fetcher.Supervisor module functions.
  Supported options:\n#{NimbleOptions.docs(@fetcher_supervisor_schema)}
  """
  @spec fetcher_supervisor_options(opts :: keyword()) ::
          validated_options :: [fetcher_supervisor_option()] | map()
  def fetcher_supervisor_options(opts \\ []) do
    NimbleOptions.validate!(opts, @fetcher_supervisor_schema)
  end

  ## Fetcher Module Options

  @fetcher_schema NimbleOptions.new!(
                    Keyword.take(@options, ~w(use_cache schedular_interval feed_fn)a)
                  )

  @type fetcher_option() :: unquote(NimbleOptions.option_typespec(@fetcher_schema))

  def fetcher_schema, do: @fetcher_schema

  @doc """
  Validate and return the options for the Forex.Fetcher module functions.
  Supported options:\n#{NimbleOptions.docs(@fetcher_schema)}
  """
  @spec fetcher_options(opts :: keyword()) :: validated_options :: [fetcher_option()] | map()
  def fetcher_options(opts \\ []) do
    NimbleOptions.validate!(opts, @fetcher_schema)
  end

  ## Currency Module Options

  @currency_schema NimbleOptions.new!(Keyword.take(@options, ~w(format round)a))

  @type currency_option() :: unquote(NimbleOptions.option_typespec(@currency_schema))

  def currency_schema, do: @currency_schema

  @doc """
  Validate and return the options for the Forex.Currency module functions.

  Supported options:\n#{NimbleOptions.docs(@currency_schema)}
  """
  @spec currency_options(opts :: keyword()) :: validated_options :: [currency_option()] | map()
  def currency_options(opts \\ []) do
    NimbleOptions.validate!(opts, @currency_schema)
  end
end
