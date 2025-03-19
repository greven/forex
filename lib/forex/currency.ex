defmodule Forex.Currency do
  @moduledoc """
  This module provides curreny information and utility functions.

  Only a subset of all the currencies are included in this module, since
  these are the currencies supported by the European Central Bank (ECB)
  exchange rates feed.
  """

  alias Forex.Support

  @currencies %{
    aud: %{
      name: "Australian Dollar",
      iso_code: "AUD",
      iso_numeric: "036",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Aussie Dollar"],
      alt_symbols: ["A$"],
      enabled: true
    },
    bgn: %{
      name: "Bulgarian Lev",
      iso_code: "BGN",
      iso_numeric: "975",
      symbol: "лв.",
      subunit: 0.01,
      subunit_name: "Stotinka",
      alt_names: ["kint"],
      alt_symbols: ["lev", "leva", "лев", "лева"],
      enabled: true
    },
    brl: %{
      name: "Brazilian Real",
      iso_code: "BRL",
      iso_numeric: "986",
      symbol: "R$",
      subunit: 0.01,
      subunit_name: "Centavo",
      alt_names: ["Real"],
      alt_symbols: [],
      enabled: true
    },
    cad: %{
      name: "Canadian Dollar",
      iso_code: "CAD",
      iso_numeric: "124",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["C$", "CA$", "CAD$", "Can$"],
      enabled: true
    },
    chf: %{
      name: "Swiss Franc",
      iso_code: "CHF",
      iso_numeric: "756",
      symbol: "CHF",
      subunit: 0.01,
      subunit_name: "Rappen",
      alt_names: [],
      alt_symbols: ["SFr", "Fr"],
      enabled: true
    },
    cny: %{
      name: "Chinese Renminbi Yuan",
      iso_code: "CNY",
      iso_numeric: "156",
      symbol: "¥",
      subunit: 0.01,
      subunit_name: "Fen",
      alt_names: ["Chinese Yuan", "Renminbi", "Yuan"],
      alt_symbols: ["CN¥", "元", "CN元"],
      enabled: true
    },
    cyp: %{
      name: "Cypriot Pound",
      iso_code: "CYP",
      iso_numeric: "196",
      symbol: "£",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    czk: %{
      name: "Czech Koruna",
      iso_code: "CZK",
      iso_numeric: "203",
      symbol: "Kč",
      subunit: 0.01,
      subunit_name: "Haléř",
      alt_names: ["Czech Crown"],
      alt_symbols: [],
      enabled: true
    },
    dkk: %{
      name: "Danish Krone",
      iso_code: "DKK",
      iso_numeric: "208",
      symbol: "kr.",
      subunit: 0.01,
      subunit_name: "Øre",
      alt_names: [],
      alt_symbols: ["DKK"],
      enabled: true
    },
    eek: %{
      name: "Estonian Kroon",
      iso_code: "EEK",
      iso_numeric: "233",
      symbol: "kr",
      subunit: 0.01,
      subunit_name: "Senti",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    eur: %{
      name: "Euro",
      iso_code: "EUR",
      iso_numeric: "978",
      symbol: "€",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    gbp: %{
      name: "British Pound Sterling",
      iso_code: "GBP",
      iso_numeric: "826",
      symbol: "£",
      subunit: 0.01,
      subunit_name: "Penny",
      alt_names: ["British Pound", "Pound", "Pound Sterling"],
      alt_symbols: [],
      enabled: true
    },
    hkd: %{
      name: "Hong Kong Dollar",
      iso_code: "HKD",
      iso_numeric: "344",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["HK$"],
      enabled: true
    },
    hrk: %{
      name: "Croatian Kuna",
      iso_code: "HRK",
      iso_numeric: "191",
      symbol: "kn",
      subunit: 0.01,
      subunit_name: "Lipa",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    huf: %{
      name: "Hungarian Forint",
      iso_code: "HUF",
      iso_numeric: "348",
      symbol: "Ft",
      subunit: 0.01,
      subunit_name: "Fillér",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    idr: %{
      name: "Indonesian Rupiah",
      iso_code: "IDR",
      iso_numeric: "360",
      symbol: "Rp",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    ils: %{
      name: "Israeli Sheqel",
      iso_code: "ILS",
      iso_numeric: "376",
      symbol: "₪",
      subunit: 0.01,
      subunit_name: "Agora",
      alt_names: ["Sheqel"],
      alt_symbols: ["ש״ח", "NIS"],
      enabled: true
    },
    inr: %{
      name: "Indian Rupee",
      iso_code: "INR",
      iso_numeric: "356",
      symbol: "₹",
      subunit: 0.01,
      subunit_name: "Paisa",
      alt_names: ["Rupee"],
      alt_symbols: ["Rs", "৳", "૱", "௹", "रु", "₨"],
      enabled: true
    },
    isk: %{
      name: "Icelandic Króna",
      iso_code: "ISK",
      iso_numeric: "352",
      symbol: "kr.",
      subunit: 0.01,
      subunit_name: "Eyrir",
      alt_names: ["Icelandic Crown", "króna"],
      alt_symbols: ["Íkr"],
      enabled: true
    },
    jpy: %{
      name: "Japanese Yen",
      iso_code: "JPY",
      iso_numeric: "392",
      symbol: "¥",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: ["Yen"],
      alt_symbols: ["円", "圓"],
      enabled: true
    },
    krw: %{
      name: "South Korean Won",
      iso_code: "KRW",
      iso_numeric: "410",
      symbol: "₩",
      subunit: 0.01,
      subunit_name: "Jeon",
      alt_names: ["Won"],
      alt_symbols: [],
      enabled: true
    },
    ltl: %{
      name: "Lithuanian Litas",
      iso_code: "LTL",
      iso_numeric: "440",
      symbol: "Lt",
      subunit: 0.01,
      subunit_name: "Centas",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    lvl: %{
      name: "Latvian Lat",
      iso_code: "LVL",
      iso_numeric: "428",
      symbol: "Ls",
      subunit: 0.01,
      subunit_name: "Santīms",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    mxn: %{
      name: "Mexican Peso",
      iso_code: "MXN",
      iso_numeric: "484",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Centavo",
      alt_names: ["Peso"],
      alt_symbols: ["MEX$"],
      enabled: true
    },
    mtl: %{
      name: "Maltese Lira",
      iso_code: "MTL",
      iso_numeric: "470",
      symbol: "₤",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    myr: %{
      name: "Malaysian Ringgit",
      iso_code: "MYR",
      iso_numeric: "458",
      symbol: "RM",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    nok: %{
      name: "Norwegian Krone",
      iso_code: "NOK",
      iso_numeric: "578",
      symbol: "kr",
      subunit: 0.01,
      subunit_name: "Øre",
      alt_names: ["Norwegian Crown"],
      alt_symbols: [],
      enabled: true
    },
    nzd: %{
      name: "New Zealand Dollar",
      iso_code: "NZD",
      iso_numeric: "554",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["NZ$"],
      enabled: true
    },
    php: %{
      name: "Philippine Peso",
      iso_code: "PHP",
      iso_numeric: "608",
      symbol: "₱",
      subunit: 0.01,
      subunit_name: "Sentimo",
      alt_names: [],
      alt_symbols: ["PHP", "PhP", "P"],
      enabled: true
    },
    pln: %{
      name: "Polish Złoty",
      iso_code: "PLN",
      iso_numeric: "985",
      symbol: "zł",
      subunit: 0.01,
      subunit_name: "Grosz",
      alt_names: ["Złoty", "Polish Zloty"],
      alt_symbols: [],
      enabled: true
    },
    rol: %{
      name: "Romanian Leu",
      iso_code: "ROL",
      iso_numeric: "642",
      symbol: "L",
      subunit: 0.01,
      subunit_name: "Ban",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    ron: %{
      name: "Romanian Leu",
      iso_code: "RON",
      iso_numeric: "946",
      symbol: "Lei",
      subunit: 0.01,
      subunit_name: "Bani",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    rub: %{
      name: "Russian Ruble",
      iso_code: "RUB",
      iso_numeric: "643",
      symbol: "₽",
      subunit: 0.01,
      subunit_name: "Kopeck",
      alt_names: ["Rouble", "Russian Rouble"],
      alt_symbols: ["руб.", "р."],
      enabled: false
    },
    sek: %{
      name: "Swedish Krona",
      iso_code: "SEK",
      iso_numeric: "752",
      symbol: "kr",
      subunit: 0.01,
      subunit_name: "Öre",
      alt_names: ["Swedish Crown"],
      alt_symbols: ["SEK"],
      enabled: true
    },
    sgd: %{
      name: "Singapore Dollar",
      iso_code: "SGD",
      iso_numeric: "702",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["S$"],
      enabled: true
    },
    skk: %{
      name: "Slovak Koruna",
      iso_code: "SKK",
      iso_numeric: "703",
      symbol: "Sk",
      subunit: 0.01,
      subunit_name: "Halier",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    sit: %{
      name: "Slovenian Tolar",
      iso_code: "SIT",
      iso_numeric: "705",
      symbol: "T",
      subunit: 0.01,
      subunit_name: "Stotinia",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    thb: %{
      name: "Thai Baht",
      iso_code: "THB",
      iso_numeric: "764",
      symbol: "฿",
      subunit: 0.01,
      subunit_name: "Satang",
      alt_names: [],
      alt_symbols: [],
      enabled: true
    },
    trl: %{
      name: "Turkish Lira",
      iso_code: "TRL",
      iso_numeric: "792",
      symbol: "₺",
      subunit: 0.01,
      subunit_name: "Kuruş",
      alt_names: [],
      alt_symbols: [],
      enabled: false
    },
    try: %{
      name: "Turkish Lira",
      iso_code: "TRY",
      iso_numeric: "949",
      symbol: "₺",
      subunit: 0.01,
      subunit_name: "kuruş",
      alt_names: [],
      alt_symbols: ["TL"],
      enabled: true
    },
    usd: %{
      name: "United States Dollar",
      iso_code: "USD",
      iso_numeric: "840",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Dollar", "American Dollar"],
      alt_symbols: ["US$"],
      enabled: true
    },
    zar: %{
      name: "South African Rand",
      iso_code: "ZAR",
      iso_numeric: "710",
      symbol: "R",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Rand"],
      alt_symbols: [],
      enabled: true
    }
  }

  ## Guards

  @doc false
  defguard is_currency_code(currency_code)
           when (is_atom(currency_code) or is_binary(currency_code)) and not is_nil(currency_code)

  ## Public API

  @doc """
  Get all list of all currencies, including disabled currencies (necessary,
  since historical rates may include disabled currencies in the past).
  """
  def all(keys \\ :atoms)

  def all(:atoms) do
    Map.new(@currencies)
  end

  def all(:strings) do
    @currencies
    |> Map.new(fn {code, currency} ->
      {Support.stringify_code(code), currency}
    end)
  end

  @doc """
  Get all list of all the available currencies (enabled currencies), that
  is, all the currencies that are supported by the ECB at the present time.
  """
  def available(keys \\ :atoms)

  def available(:atoms) do
    all(:atoms)
    |> Enum.filter(fn {_code, currency} -> currency.enabled end)
    |> Enum.map(fn {code, currency} -> {code, Map.drop(currency, [:enabled])} end)
    |> Map.new()
  end

  def available(:strings) do
    all(:strings)
    |> Enum.filter(fn {_code, currency} -> currency.enabled end)
    |> Enum.map(fn {code, currency} -> {code, Map.drop(currency, [:enabled])} end)
    |> Map.new()
  end

  @doc """
  Get all list of all the disabled currencies, that is,
  all the currencies that are not supported by the ECB at the present time but
  may have been supported in the past and are included in historical rates.
  """
  def disabled(keys \\ :atoms)

  def disabled(:atoms) do
    all(:atoms)
    |> Enum.filter(fn {_code, currency} -> not currency.enabled end)
    |> Enum.map(fn {code, currency} -> {code, Map.drop(currency, [:enabled])} end)
    |> Map.new()
  end

  def disabled(:strings) do
    all(:strings)
    |> Enum.filter(fn {_code, currency} -> not currency.enabled end)
    |> Enum.map(fn {code, currency} -> {code, Map.drop(currency, [:enabled])} end)
    |> Map.new()
  end

  @doc """
  Get the currency information for the given ISO code.

  Example:

      iex> Forex.Currency.get(:eur)
      {:ok, %{name: "Euro", ...}}
      iex> Forex.Currency.get("USD")
      {:ok, %{name: "United States Dollar", ...}}
      iex> Forex.Currency.get(:GBP)
      {:ok, %{name: "British Pound Sterling", ...}}
  """
  def get(iso_code) when is_binary(iso_code) do
    iso_code
    |> Support.atomize_code()
    |> get()
  end

  def get(iso_code) when is_atom(iso_code) do
    iso_code = Support.atomize_code(iso_code)

    if exists?(iso_code) do
      {:ok, Map.get(all(), iso_code)}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Get the currency information for the given ISO code.
  The same as `get/1`, but raises a `Forex.CurrencyError` if the currency is not found.
  """
  def get!(iso_code) do
    case get(iso_code) do
      {:ok, currency} -> currency
      {:error, _} -> raise Forex.CurrencyError, "Currency not found for #{iso_code}"
    end
  end

  @doc """
  Check if a currency with the given ISO exists, i.e.,
  if it is supported by the European Central Bank (ECB) service.

  Example:

      iex> Forex.Currency.exists?(:eur)
      true
      iex> Forex.Currency.exists?("USD")
      true
      iex> Forex.Currency.exists?(:GBP)
      true
      iex> Forex.Currency.exists?(:xpt)
      false
      iex> Forex.Currency.exists?(:invalid)
      false
      iex> Forex.Currency.exists?(nil)
      false
  """
  def exists?(iso_code) when is_binary(iso_code) do
    iso_code
    |> Support.atomize_code()
    |> exists?()
  rescue
    _ -> false
  end

  def exists?(iso_code) when is_atom(iso_code) do
    iso_code = Support.atomize_code(iso_code)
    Map.has_key?(all(), iso_code)
  rescue
    _ -> false
  end

  @doc """
  Exchange a given amount from one currency to another using ECB rates.

  ## Options
    * `:format` - Output format (`:decimal` or `:string`). Defaults to `:decimal`.
    * `:round` - Decimal places for rounding. Defaults to `5`.

  ## Examples

      iex> Forex.exchange(100, :USD, :EUR)
      {:ok, Decimal.new("95.28300")}

      iex> Forex.exchange(100, "USD", "EUR", format: :string)
      {:ok, "95.28300"}

      iex> Forex.exchange(100, "INVALID", "EUR")
      {:error, :invalid_currency}
  """
  def exchange(amount, from, to, opts \\ [])
      when is_currency_code(from) and is_currency_code(to) do
    with from <- Support.stringify_code(from),
         to <- Support.stringify_code(to),
         {:ok, _} <- validate_currencies(from, to),
         {:ok, %{rates: rates}} <- Forex.current_rates(base: from, keys: :strings),
         {:ok, result} <- do_exchange(amount, Map.get(rates, from), Map.get(rates, to)) do
      format = Keyword.get(opts, :format, :decimal)
      round = Keyword.get(opts, :round, 5)

      result =
        result
        |> Support.round_value(round)
        |> Support.format_value(format)

      {:ok, result}
    else
      {:error, _} = error -> error
      _ -> {:error, :exchange_error}
    end
  end

  @doc """
  Exchange a given amount from one currency to another using ECB rates.
  Like `exchange/4`, but raises a `Forex.CurrencyError` if the exchange fails.
  """
  def exchange!(amount, from, to, opts \\ []) do
    case exchange(amount, from, to, opts) do
      {:ok, result} -> result
      {:error, _} -> raise Forex.CurrencyError, "Currency exchange failed"
    end
  end

  defp validate_currencies(from, to) do
    case {exists?(from), exists?(to)} do
      {true, true} -> {:ok, {from, to}}
      _ -> {:error, :invalid_currency}
    end
  end

  defp do_exchange(amount, from_rate, to_rate)
       when not is_nil(from_rate) and not is_nil(to_rate) do
    {:ok,
     amount
     |> Support.format_value(:decimal)
     |> Decimal.mult(Decimal.div(to_rate, from_rate))}
  end

  defp do_exchange(_, _, _), do: {:error, :invalid_exchange}

  ## Helpers

  @doc """
  This function is used to rebase the rates to a new base currency.

  The default base currency is `:EUR`, so if the base_currency is a different
  currency, the rates will be converted to the new currency base.
  """
  def maybe_rebase(eur_rates, base_currency) when is_atom(base_currency) do
    base_currency
    |> Atom.to_string()
    |> String.upcase()
    |> then(&maybe_rebase(eur_rates, &1))
  end

  def maybe_rebase(eur_rates, "EUR"), do: {:ok, eur_rates}

  def maybe_rebase(eur_rates, new_base) when is_currency_code(new_base) do
    if exists?(new_base) do
      {:ok, rebase(eur_rates, new_base)}
    else
      {Forex.CurrencyError, "Base currency not found in the available currency rates"}
    end
  end

  @doc """
  Given a list of rates in the form of %{currency_code() => Decimal.t()},
  convert the rates to a new currency base.
  """
  def rebase(rates, base) do
    # Find the rate for the new base currency
    base_rate = Enum.find(rates, &(&1.currency == base))

    case base_rate do
      nil ->
        rates

      %{rate: base_rate_value} ->
        rates
        |> Enum.map(fn
          # Set base currency rate to 1
          %{currency: ^base} = rate ->
            %{rate | rate: Decimal.new("1.00000")}

          # Convert other rates relative to new base
          %{rate: rate_value} = rate ->
            %{rate | rate: convert_rate(Decimal.new(rate_value), base_rate_value)}
        end)
    end
  end

  # Converts a currency value from one currency to another.
  defp convert_rate(%Decimal{} = currency_value, new_base_value) do
    Decimal.div(currency_value, new_base_value)
  end
end
