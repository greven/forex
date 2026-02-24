defmodule Forex.CurrencyTest do
  use ExUnit.Case, async: true

  import Forex.FeedFixtures
  import Forex.RatesFixtures

  alias Forex.Currency

  @disabled_currencies ~w(rub)a

  @historic_currencies ~w(cyp eek hrk ltl lvl mtl rol sit skk trl)a

  @available_currencies ~w(
    aud bgn brl cad chf cny czk dkk
    eur gbp hkd huf idr ils inr isk
    jpy krw mxn myr nok nzd php pln
    ron sek sgd thb try usd zar
    )a

  @currency_keys ~w(
    name
    symbol
    iso_code
    iso_numeric
    subunit
    subunit_name
    alt_names
    alt_symbols
  )a

  describe "is_currency_code/1" do
    test "returns true for valid currency code formats" do
      require Forex.Currency

      assert Currency.is_currency_code("USD")
      assert Currency.is_currency_code("EUR")
      assert Currency.is_currency_code(:USD)
      assert Currency.is_currency_code(:EUR)
    end

    test "returns false for invalid formats" do
      require Forex.Currency

      refute Currency.is_currency_code(123)
      refute Currency.is_currency_code(%{})
      refute Currency.is_currency_code([])
      refute Currency.is_currency_code(nil)
    end
  end

  describe "is_currency_amount/1" do
    test "returns true for valid currency amount formats" do
      require Forex.Currency

      assert Currency.is_currency_amount(100)
      assert Currency.is_currency_amount(123.45)
      assert Currency.is_currency_amount("100")
      assert Currency.is_currency_amount("123.45")
      assert Currency.is_currency_amount(Decimal.new("100.0"))
    end

    test "returns false for invalid formats" do
      require Forex.Currency

      refute Currency.is_currency_amount(%{})
      refute Currency.is_currency_amount([])
      refute Currency.is_currency_amount(nil)
    end
  end

  describe "all/0" do
    test "returns all the currencies" do
      keys = Currency.all() |> Map.keys()
      all_keys = @available_currencies ++ @disabled_currencies ++ @historic_currencies

      assert Enum.sort(keys) == Enum.sort(all_keys)
    end

    test "returns a map of all currencies with the iso code as the key" do
      currencies = Currency.all()

      currency_keys =
        Map.get(currencies, :eur)
        |> Map.from_struct()
        |> Map.keys()
        |> Enum.sort()

      assert is_map(Map.get(currencies, :eur))
      assert currency_keys == Enum.to_list(@currency_keys) |> Enum.sort()
    end

    test "returns a map of all currencies with the keys as strings" do
      currencies = Currency.all(:strings)

      currency_keys =
        Map.get(currencies, "EUR")
        |> Map.from_struct()
        |> Map.keys()
        |> Enum.sort()

      assert is_map(Map.get(currencies, "EUR"))
      assert currency_keys == Enum.to_list(@currency_keys) |> Enum.sort()
    end
  end

  describe "available/0" do
    test "returns all the available currencies" do
      keys = Currency.available() |> Map.keys()

      assert Enum.sort(keys) == @available_currencies
    end

    test "returns a map of all the available currencies with the iso code as the key" do
      currencies = Currency.available()

      currency_keys =
        Map.get(currencies, :eur)
        |> Map.from_struct()
        |> Map.keys()
        |> Enum.sort()

      assert is_map(Map.get(currencies, :eur))
      assert currency_keys == Enum.to_list(@currency_keys) |> Enum.sort()
    end

    test "returns a map of all the available currencies with the keys as strings" do
      currencies = Currency.available(:strings)

      currency_keys =
        Map.get(currencies, "EUR")
        |> Map.from_struct()
        |> Map.keys()
        |> Enum.sort()

      assert is_map(Map.get(currencies, "EUR"))
      assert currency_keys == Enum.to_list(@currency_keys) |> Enum.sort()
    end
  end

  describe "disabled/0" do
    test "returns all the disabled currencies" do
      keys =
        Currency.disabled()
        |> Map.keys()

      assert Enum.sort(keys) == Enum.sort(@disabled_currencies ++ @historic_currencies)
    end
  end

  describe "disabled/1" do
    test "returns all the disabled currencies as strings" do
      [key | _] = keys_as_strings = Currency.disabled(:strings) |> Map.keys()

      disabled_keys =
        Enum.map(
          @disabled_currencies ++ @historic_currencies,
          fn code -> to_string(code) |> String.upcase() end
        )

      assert is_binary(key)
      assert Enum.sort(keys_as_strings) == Enum.sort(disabled_keys)
    end
  end

  describe "get/1" do
    test "returns the currency with the given iso code" do
      {:ok, currency} = Currency.get(:eur)

      assert currency.iso_code == "EUR"
      assert currency.name == "Euro"
      assert currency.symbol == "€"
    end

    test "returns the currency when using the iso code as a lowercase string" do
      {:ok, currency} = Currency.get("eur")
      assert currency.iso_code == "EUR"
    end

    test "returns the currency when using the iso code as an uppercase string" do
      {:ok, currency} = Currency.get("EUR")
      assert currency.iso_code == "EUR"
    end

    test "returns the currency when using the iso code in mixed case" do
      {:ok, currency} = Currency.get("eUr")
      assert currency.iso_code == "EUR"
    end

    test "returns {:error, :not_found} if the currency with the given iso code does not exist" do
      assert Currency.get("XYZ") == {:error, :not_found}
    end
  end

  describe "get!/1" do
    test "returns the currency with the given iso code" do
      currency = Currency.get!(:eur)

      assert currency.iso_code == "EUR"
      assert currency.name == "Euro"
      assert currency.symbol == "€"
    end

    test "raises an exception if the currency with the given iso code does not exist" do
      assert_raise Forex.CurrencyError, "Currency not found for XYZ", fn ->
        Currency.get!("XYZ")
      end
    end
  end

  describe "exists?/1" do
    test "returns true if the currency with the given iso code exists" do
      assert Currency.exists?("EUR")
      assert Currency.exists?("eur")
      assert Currency.exists?(:eur)
      assert Currency.exists?(:EUR)
    end

    test "returns false if the currency with the given iso code does not exist" do
      refute Currency.exists?("XYZ")
      refute Currency.exists?(:xyz)
      refute Currency.exists?(nil)
    end

    test "returns false for a binary converted to a non-existing atom" do
      refute Currency.exists?("abcdef")
      refute Currency.exists?(:ABCDEF)
    end
  end

  describe "exchange_rates/5" do
    test "successfully converts between currencies given a list of rates" do
      rates = single_forex_fixture()

      assert {:ok, Decimal.new("1.00000")} == Currency.exchange_rates(rates, 1, :eur, :eur)
      assert {:ok, Decimal.new("1.20210")} == Currency.exchange_rates(rates, 1, :gbp, :eur)
      assert {:ok, Decimal.new("1.00000")} == Currency.exchange_rates({:ok, rates}, 1, :eur, :eur)
    end

    test "successfully converts between currencies given a list of rates and format options" do
      rates = single_forex_fixture()

      assert {:ok, "1.00000"} == Currency.exchange_rates(rates, 1, :eur, :eur, format: :string)
      assert {:ok, "1.20210"} == Currency.exchange_rates(rates, 1, :gbp, :eur, format: :string)

      assert {:ok, "1.00000"} ==
               Currency.exchange_rates(rates, 1, :eur, :eur, format: :string)

      assert {:ok, Decimal.new("1.20210")} ==
               Currency.exchange_rates(rates.rates, 1, :gbp, :eur, format: :decimal)

      assert {:ok, Decimal.new("1.20")} ==
               Currency.exchange_rates(rates, 1, :gbp, :eur, format: :decimal, round: 2)

      assert {:ok, Decimal.new("1.00000")} ==
               Currency.exchange_rates({:ok, rates}, 1, :eur, :eur, format: :decimal)
    end

    test "returns an error on invalid exchanges" do
      rates = single_forex_fixture()

      assert {:error, :invalid_exchange} == Currency.exchange_rates(rates, nil, :eur, :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates(rates, [], :eur, :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates(rates, 1, nil, :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates(rates, 1, [], :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates([], 1, [], :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates([], 7, :eur, :usd)
      assert {:error, :invalid_exchange} == Currency.exchange_rates(nil, 7, :eur, :usd)
    end

    test "returns an error if the currency with the given iso code does not exist" do
      rates = single_forex_fixture()
      assert {:error, :invalid_currency} == Currency.exchange_rates(rates, 1, :eur, :xyz)
    end
  end

  describe "exchange_rates!/5" do
    test "successfully converts between currencies given a list of rates" do
      rates = single_forex_fixture()

      assert Decimal.new("1.00000") == Currency.exchange_rates!(rates, 1, :eur, :eur)
      assert Decimal.new("1.20210") == Currency.exchange_rates!(rates, 1, :gbp, :eur)
      assert Decimal.new("1.00000") == Currency.exchange_rates!({:ok, rates}, 1, :eur, :eur)
    end

    test "successfully converts between currencies given a list of rates and format options" do
      rates = single_forex_fixture()

      assert "1.00000" == Currency.exchange_rates!(rates, 1, :eur, :eur, format: :string)
      assert "1.20210" == Currency.exchange_rates!(rates, 1, :gbp, :eur, format: :string)

      assert Decimal.new("1.00000") ==
               Currency.exchange_rates!(rates, 1, :eur, :eur, format: :decimal)

      assert Decimal.new("1.20210") ==
               Currency.exchange_rates!(rates.rates, 1, :gbp, :eur, format: :decimal)

      assert Decimal.new("1.20") ==
               Currency.exchange_rates!(rates, 1, :gbp, :eur, format: :decimal, round: 2)

      assert Decimal.new("1.00000") ==
               Currency.exchange_rates!({:ok, rates}, 1, :eur, :eur, format: :decimal)
    end

    test "raises an error on invalid exchanges" do
      rates = single_forex_fixture()

      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange_rates!(rates, nil, :eur, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange_rates!(rates, [], :eur, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange_rates!(rates, 1, nil, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange_rates!(rates, 1, [], :usd)
      end
    end
  end

  describe "maybe_rebase/2" do
    setup do
      rates = single_rates_fixture() |> List.first() |> Map.get(:rates)

      %{rates: rates}
    end

    test "returns original rates when base currency is EUR", %{rates: rates} do
      assert {:ok, ^rates} = Currency.maybe_rebase(rates, "EUR")
    end

    test "converts rates to new base currency", %{rates: rates} do
      assert {:ok, rebased} = Currency.maybe_rebase(rates, "USD")

      # Since EUR is the default base currency, it should be 1.0000
      rebased = rebased ++ [%{currency: "EUR", rate: Decimal.new("1.0000")}]

      # USD should be 1.0000
      usd = Enum.find(rebased, &(&1.currency == "USD"))
      assert Decimal.eq?(Decimal.new(usd.rate), Decimal.new(1))

      # EUR should be original EUR/USD rate
      eur = Enum.find(rebased, &(&1.currency == "EUR"))
      expected_eur = Decimal.div(Decimal.new("1.0000"), Decimal.new(usd.rate))
      assert Decimal.eq?(Decimal.new(eur.rate), expected_eur)

      # GBP should be original GBP/USD rate
      gbp = Enum.find(rebased, &(&1.currency == "GBP"))
      expected_gbp = Decimal.div(Decimal.new("0.83188"), Decimal.new("1.0772"))
      assert Decimal.eq?(Decimal.new(gbp.rate), expected_gbp)

      # JPY should be original JPY/USD rate
      jpy = Enum.find(rebased, &(&1.currency == "JPY"))
      expected_jpy = Decimal.div(Decimal.new("164.18"), Decimal.new("1.0772"))
      assert Decimal.eq?(Decimal.new(jpy.rate), expected_jpy)
    end

    test "accepts atom input for currency code", %{rates: rates} do
      assert {:ok, _} = Currency.maybe_rebase(rates, :usd)
    end

    test "returns an error for invalid base currency", %{rates: rates} do
      assert {:error, :base_currency_not_found} = Currency.maybe_rebase(rates, "INVALID")
    end

    test "handles case when base currency is not in rates list", %{rates: rates} do
      rates_without_usd = Enum.reject(rates, &(&1.currency == "USD"))
      assert {:ok, unchanged_rates} = Currency.maybe_rebase(rates_without_usd, "USD")
      assert unchanged_rates == rates_without_usd
    end

    test "preserves original currency codes after rebase", %{rates: rates} do
      assert {:ok, rebased} = Currency.maybe_rebase(rates, "USD")
      original_currencies = Enum.map(rates, & &1.currency)
      rebased_currencies = Enum.map(rebased, & &1.currency)
      assert rebased_currencies -- original_currencies == []
    end
  end
end
