defmodule Forex.CurrencyTest do
  use ExUnit.Case, async: true

  import Forex.TestHelpers
  import Forex.FeedFixtures

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

  setup_all do
    setup_test_cache()

    :ok
  end

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
  end

  describe "exchange/3" do
    test "returns the amount in the target currency" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value(:usd)
      {:ok, eur_rate_value} = get_single_rate_fixture_value(:eur, base: :usd)

      assert {:ok, usd_rate_value} == Currency.exchange(1, :eur, :usd)
      assert {:ok, Decimal.mult(usd_rate_value, 10)} == Currency.exchange(10, :eur, :usd)
      assert {:ok, Decimal.new("0.00000")} == Currency.exchange(0, :eur, :usd)
      assert {:ok, usd_rate_value} == Currency.exchange(1.0, "EUR", "USD")
      assert {:ok, usd_rate_value} == Currency.exchange("1", "EUR", "USD")
      assert {:ok, usd_rate_value} == Currency.exchange("1.0", "EUR", "USD")
      assert {:ok, eur_rate_value} == Currency.exchange(1, "USD", "EUR")
      assert {:ok, Decimal.mult(eur_rate_value, 10)} == Currency.exchange(10, :usd, :eur)
      assert %Decimal{} = usd_rate_value
    end

    test "returns an error if the currency with the given iso code does not exist" do
      refute {:ok, Decimal.new("0.0000")} == Currency.exchange(1, :eur, :xyz)
      refute {:ok, Decimal.new("0.0000")} == Currency.exchange(1, :usd, :xyz)
      assert {:error, :invalid_currency} == Currency.exchange(1, "EUR", "XYZ")
    end

    test "raises an exception if an invalid amount is provided" do
      assert_raise Forex.FormatError, fn -> Currency.exchange(nil, :eur, :usd) end
      assert_raise Decimal.Error, fn -> Currency.exchange("abc", "EUR", "USD") end
    end

    test "handles negative amounts correctly" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value("USD")

      assert Currency.exchange(-100, :eur, :usd) ==
               {:ok, Decimal.mult(usd_rate_value, Decimal.new(-100))}
    end

    test "handles large numbers" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value(:usd)
      large_number = "1000000000000"
      assert {:ok, result} = Currency.exchange(large_number, "EUR", "USD")
      assert Decimal.eq?(result, Decimal.mult(usd_rate_value, Decimal.new(large_number)))
    end
  end

  describe "exchange/4" do
    test "successfully converts between currencies" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value(:usd)
      {:ok, result} = Currency.exchange(1, :eur, :usd)
      assert Decimal.eq?(result, usd_rate_value)
    end

    test "accepts format and rounding options" do
      {:ok, result} = Currency.exchange(1, :eur, :usd, format: :string, round: 2)
      assert is_binary(result)
      assert String.match?(result, ~r/^\d+\.\d{2}$/)
    end

    test "returns the amount in the target currency given valid options" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value("USD")
      {:ok, eur_rate_value} = get_single_rate_fixture_value("EUR", base: "USD")

      assert Currency.exchange(1, "EUR", "USD", format: :string) ==
               {:ok, usd_rate_value |> Decimal.round(5) |> Decimal.to_string()}

      assert Currency.exchange(1, "EUR", "USD", format: :string, round: 2) ==
               {:ok, usd_rate_value |> Decimal.round(2) |> Decimal.to_string()}

      assert Currency.exchange(1, "USD", "EUR", format: :string, round: 2) ==
               {:ok, eur_rate_value |> Decimal.round(2) |> Decimal.to_string()}
    end

    test "accepts atom currency codes" do
      {:ok, decimal_result} = Currency.exchange(1, :EUR, :USD)
      assert %Decimal{} = decimal_result
    end

    test "returns an error if the currency with the given iso code does not exist" do
      refute Currency.exchange(1, "EUR", "XYZ", format: :string) == {:ok, "0.0000"}
      refute Currency.exchange(1, "USD", "XYZ", format: :string) == {:ok, "0.0000"}
      assert Currency.exchange(1, "EUR", "XYZ", format: :string) == {:error, :invalid_currency}
    end
  end

  describe "exchange!/4" do
    test "successfully converts between currencies" do
      {:ok, usd_rate_value} = get_single_rate_fixture_value("USD")
      result = Currency.exchange!(1, "EUR", "USD")
      assert Decimal.eq?(result, usd_rate_value)
    end

    test "accepts format and rounding options" do
      result = Currency.exchange!(1, "EUR", "USD", format: :string, round: 2)
      assert is_binary(result)
      assert String.match?(result, ~r/^\d+\.\d{2}$/)
    end

    test "accepts atom currency codes" do
      decimal_result = Currency.exchange!(1, :EUR, :USD)
      assert %Decimal{} = decimal_result
    end

    test "raises CurrencyError for invalid currencies" do
      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange!(100, "INVALID", "USD")
      end

      assert_raise Forex.CurrencyError, fn ->
        Currency.exchange!(100, "EUR", "INVALID")
      end
    end

    test "raises FormatError for invalid amounts" do
      assert_raise Forex.FormatError, fn ->
        Currency.exchange!(nil, "EUR", "USD")
      end

      assert_raise Decimal.Error, fn ->
        Currency.exchange!("not_a_number", "EUR", "USD")
      end
    end
  end

  describe "maybe_rebase/2" do
    setup do
      rates = single_rate_fixture() |> List.first() |> Map.get(:rates)

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
