defmodule Forex.Currency do
  @moduledoc """
  This module provides curreny information and utility functions.

  Only a subset of all the currencies are included in this module, since
  these are the currencies supported by the European Central Bank (ECB)
  exchange rates feed.
  """

  alias Forex.Helper

  @currencies %{
    "AUD" => %{
      name: "Australian Dollar",
      iso_code: "AUD",
      iso_numeric: "036",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Aussie Dollar"],
      alt_symbols: ["A$"]
    },
    "BGN" => %{
      name: "Bulgarian Lev",
      iso_code: "BGN",
      iso_numeric: "975",
      symbol: "лв.",
      subunit: 0.01,
      subunit_name: "Stotinka",
      alt_names: ["kint"],
      alt_symbols: ["lev", "leva", "лев", "лева"]
    },
    "BRL" => %{
      name: "Brazilian Real",
      iso_code: "BRL",
      iso_numeric: "986",
      symbol: "R$",
      subunit: 0.01,
      subunit_name: "Centavo",
      alt_names: ["Real"],
      alt_symbols: []
    },
    "CAD" => %{
      name: "Canadian Dollar",
      iso_code: "CAD",
      iso_numeric: "124",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["C$", "CA$", "CAD$", "Can$"]
    },
    "CHF" => %{
      name: "Swiss Franc",
      iso_code: "CHF",
      iso_numeric: "756",
      symbol: "CHF",
      subunit: 0.01,
      subunit_name: "Rappen",
      alt_names: [],
      alt_symbols: ["SFr", "Fr"]
    },
    "CNY" => %{
      name: "Chinese Renminbi Yuan",
      iso_code: "CNY",
      iso_numeric: "156",
      symbol: "¥",
      subunit: 0.01,
      subunit_name: "Fen",
      alt_names: ["Chinese Yuan", "Renminbi", "Yuan"],
      alt_symbols: ["CN¥", "元", "CN元"]
    },
    "CZK" => %{
      name: "Czech Koruna",
      iso_code: "CZK",
      iso_numeric: "203",
      symbol: "Kč",
      subunit: 0.01,
      subunit_name: "Haléř",
      alt_names: ["Czech Crown"],
      alt_symbols: []
    },
    "DKK" => %{
      name: "Danish Krone",
      iso_code: "DKK",
      iso_numeric: "208",
      symbol: "kr.",
      subunit: 0.01,
      subunit_name: "Øre",
      alt_names: [],
      alt_symbols: ["DKK"]
    },
    "EUR" => %{
      name: "Euro",
      iso_code: "EUR",
      iso_numeric: "978",
      symbol: "€",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: []
    },
    "GBP" => %{
      name: "British Pound Sterling",
      iso_code: "GBP",
      iso_numeric: "826",
      symbol: "£",
      subunit: 0.01,
      subunit_name: "Penny",
      alt_names: ["British Pound", "Pound", "Pound Sterling"],
      alt_symbols: []
    },
    "HKD" => %{
      name: "Hong Kong Dollar",
      iso_code: "HKD",
      iso_numeric: "344",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["HK$"]
    },
    "HUF" => %{
      name: "Hungarian Forint",
      iso_code: "HUF",
      iso_numeric: "348",
      symbol: "Ft",
      subunit: 0.01,
      subunit_name: "Fillér",
      alt_names: [],
      alt_symbols: []
    },
    "IDR" => %{
      name: "Indonesian Rupiah",
      iso_code: "IDR",
      iso_numeric: "360",
      symbol: "Rp",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: [],
      alt_symbols: []
    },
    "ILS" => %{
      name: "Israeli New Sheqel",
      iso_code: "ILS",
      iso_numeric: "376",
      symbol: "₪",
      subunit: 0.01,
      subunit_name: "Agora",
      alt_names: ["Sheqel"],
      alt_symbols: ["ש״ח", "NIS"]
    },
    "INR" => %{
      name: "Indian Rupee",
      iso_code: "INR",
      iso_numeric: "356",
      symbol: "₹",
      subunit: 0.01,
      subunit_name: "Paisa",
      alt_names: ["Rupee"],
      alt_symbols: ["Rs", "৳", "૱", "௹", "रु", "₨"]
    },
    "ISK" => %{
      name: "Icelandic Króna",
      iso_code: "ISK",
      iso_numeric: "352",
      symbol: "kr.",
      subunit: 0.01,
      subunit_name: "Eyrir",
      alt_names: ["Icelandic Crown", "króna"],
      alt_symbols: ["Íkr"]
    },
    "JPY" => %{
      name: "Japanese Yen",
      iso_code: "JPY",
      iso_numeric: "392",
      symbol: "¥",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: ["Yen"],
      alt_symbols: ["円", "圓"]
    },
    "KRW" => %{
      name: "South Korean Won",
      iso_code: "KRW",
      iso_numeric: "410",
      symbol: "₩",
      subunit: 0.01,
      subunit_name: "Jeon",
      alt_names: ["Won"],
      alt_symbols: []
    },
    "MXN" => %{
      name: "Mexican Peso",
      iso_code: "MXN",
      iso_numeric: "484",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Centavo",
      alt_names: ["Peso"],
      alt_symbols: ["MEX$"]
    },
    "MYR" => %{
      name: "Malaysian Ringgit",
      iso_code: "MYR",
      iso_numeric: "458",
      symbol: "RM",
      subunit: 0.01,
      subunit_name: "Sen",
      alt_names: [],
      alt_symbols: []
    },
    "NOK" => %{
      name: "Norwegian Krone",
      iso_code: "NOK",
      iso_numeric: "578",
      symbol: "kr",
      subunit: 0.01,
      subunit_name: "Øre",
      alt_names: ["Norwegian Crown"],
      alt_symbols: []
    },
    "NZD" => %{
      name: "New Zealand Dollar",
      iso_code: "NZD",
      iso_numeric: "554",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["NZ$"]
    },
    "PHP" => %{
      name: "Philippine Peso",
      iso_code: "PHP",
      iso_numeric: "608",
      symbol: "₱",
      subunit: 0.01,
      subunit_name: "Sentimo",
      alt_names: [],
      alt_symbols: ["PHP", "PhP", "P"]
    },
    "PLN" => %{
      name: "Polish Złoty",
      iso_code: "PLN",
      iso_numeric: "985",
      symbol: "zł",
      subunit: 0.01,
      subunit_name: "Grosz",
      alt_names: ["Złoty", "Polish Zloty"],
      alt_symbols: []
    },
    "RON" => %{
      name: "Romanian Leu",
      iso_code: "RON",
      iso_numeric: "946",
      symbol: "Lei",
      subunit: 0.01,
      subunit_name: "Bani",
      alt_names: [],
      alt_symbols: []
    },
    "RUB" => %{
      name: "Russian Ruble",
      iso_code: "RUB",
      iso_numeric: "643",
      symbol: "₽",
      subunit: 0.01,
      subunit_name: "Kopeck",
      alt_names: ["Rouble", "Russian Rouble"],
      alt_symbols: ["руб.", "р."]
    },
    "SEK" => %{
      name: "Swedish Krona",
      iso_code: "SEK",
      iso_numeric: "752",
      symbol: "kr",
      subunit: 0.01,
      subunit_name: "Öre",
      alt_names: ["Swedish Crown"],
      alt_symbols: ["SEK"]
    },
    "SGD" => %{
      name: "Singapore Dollar",
      iso_code: "SGD",
      iso_numeric: "702",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: [],
      alt_symbols: ["S$"]
    },
    "THB" => %{
      name: "Thai Baht",
      iso_code: "THB",
      iso_numeric: "764",
      symbol: "฿",
      subunit: 0.01,
      subunit_name: "Satang",
      alt_names: [],
      alt_symbols: []
    },
    "TRY" => %{
      name: "Turkish Lira",
      iso_code: "TRY",
      iso_numeric: "949",
      symbol: "₺",
      subunit: 0.01,
      subunit_name: "kuruş",
      alt_names: [],
      alt_symbols: ["TL"]
    },
    "USD" => %{
      name: "United States Dollar",
      iso_code: "USD",
      iso_numeric: "840",
      symbol: "$",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Dollar", "American Dollar"],
      alt_symbols: ["US$"]
    },
    "ZAR" => %{
      name: "South African Rand",
      iso_code: "ZAR",
      iso_numeric: "710",
      symbol: "R",
      subunit: 0.01,
      subunit_name: "Cent",
      alt_names: ["Rand"],
      alt_symbols: []
    }
  }

  def all, do: @currencies

  def get(iso_code) when is_atom(iso_code) do
    iso_code
    |> Atom.to_string()
    |> String.upcase()
    |> get()
  end

  def get(iso_code), do: Map.get(@currencies, iso_code)

  def rebase(rates, opts) do
    format = Keyword.get(opts, :format)
    base_currency = Keyword.get(opts, :base)

    new_base_rate =
      case Map.get(rates, base_currency) do
        nil -> nil
        rate -> Decimal.new(rate)
      end

    cond do
      base_currency == "EUR" ->
        Map.put(rates, "EUR", Helper.format_value(1, format))

      new_base_rate == nil ->
        {Forex.CurrencyError, "Base currency not found in the available currency rates"}

      true ->
        rates
        |> Enum.map(fn {currency, rate_value} ->
          {currency, convert(rate_value, new_base_rate, format)}
        end)
        |> Map.new()
        |> Map.put("EUR", Decimal.div(1, new_base_rate) |> Helper.format_value(format))
        |> Map.put(base_currency, Helper.format_value(1, format))
    end
  end

  def convert(%Decimal{} = currency_value, new_base_value, :decimal) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 6})
    Decimal.div(currency_value, new_base_value)
  end

  def convert(currency_value, new_base_value, :string) when is_binary(currency_value) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 6})
    Decimal.div(Decimal.new(currency_value), new_base_value) |> Decimal.to_string()
  end
end
