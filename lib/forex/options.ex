defmodule Forex.Options do
  @moduledoc """
  Options/configuration module for the Forex.Supervisor and rates functions (`latest_rates/1`,
  `last_ninety_days_rates/1`, `historic_rates/1`, `get_historic_rate/2`, `get_historic_rates_between/3`
  and its variations).
  """

  @currency_atoms ~w(
    aud bgn brl cad chf cny czk dkk eur gbp hkd
    huf idr ils inr isk jpy krw mxn myr nok nzd
    php pln ron sek sgd thb try usd zar AUD BGN
    BRL CAD CHF CNY CZK DKK EUR GBP HKD HUF IDR
    ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN
    RON SEK SGD THB TRY USD ZAR)a

  @allowed_codes @currency_atoms ++ Enum.map(@currency_atoms, &to_string/1)

  @base_options base: [
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
                symbols: [
                  type: {:or, [{:list, {:in, @allowed_codes}}, nil]},
                  doc: "Currency codes to include"
                ],
                keys: [type: {:in, ~w(strings atoms)a}, default: :atoms, doc: "Map key format"],
                use_cache: [type: :boolean, default: true, doc: "Whether to use cached rates"],
                feed_fn: [
                  type: :mfa,
                  doc: "Optional custom feed function as `{module, function, args}`"
                ]

  @rates_schema NimbleOptions.new!(@base_options)

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

  @currency_schema NimbleOptions.new!(Keyword.take(@base_options, [:format, :round]))

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
