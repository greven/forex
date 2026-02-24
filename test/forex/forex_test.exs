defmodule ForexTest do
  use ExUnit.Case, async: true

  import Forex.RatesFixtures

  describe "json_library/0" do
    test "returns the configured JSON library" do
      assert Forex.json_library() == JSON
    end
  end

  describe "currency operations" do
    test "available_currencies/0 returns list of supported currencies" do
      currencies = Forex.available_currencies()
      assert is_list(currencies)
      assert length(currencies) == 31
      assert :eur in currencies
      assert :usd in currencies
    end

    test "available_currencies/1 returns list of supported currencies as strings" do
      currencies = Forex.available_currencies(:strings)
      assert is_list(currencies)
      assert length(currencies) == 31
      assert "EUR" in currencies
      assert "USD" in currencies
    end

    test "list_currencies/0 returns map of currency details" do
      currencies = Forex.list_currencies()

      assert is_map(currencies)
      assert %{name: "Euro", symbol: "€"} = currencies.eur
      assert currencies == Forex.list_currencies(:atoms)
    end

    test "list_currencies/1 returns map of currency details as strings" do
      currencies = Forex.list_currencies(:strings)
      assert is_map(currencies)
      assert %{name: "Euro", symbol: "€"} = currencies["EUR"]
    end

    test "currency_options/0 returns formatted currency pairs" do
      options = Forex.currency_options()
      assert {"United States Dollar", :usd} in options
      assert {"Euro", :eur} in options
      assert length(options) == length(Forex.available_currencies())
      assert {"Euro", "EUR"} in Forex.currency_options(:strings)
    end

    test "get_currency/1 returns currency information" do
      assert {:ok, currency} = Forex.get_currency("EUR")
      assert currency.name == "Euro"
      assert currency.symbol == "€"

      assert {:error, :not_found} = Forex.get_currency("INVALID")
    end

    test "get_currency!/1 returns currency information" do
      currency = Forex.get_currency!("EUR")
      assert currency.name == "Euro"
      assert currency.symbol == "€"
    end

    test "get_currency!/1 raises on invalid currency" do
      assert_raise Forex.CurrencyError, fn ->
        Forex.get_currency!("INVALID")
      end
    end
  end

  describe "latest_rates/0" do
    test "returns latest exchange rates" do
      {:ok, %{rates: rates} = rate} = Forex.latest_rates()

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "returns rates without using the cache" do
      {:ok, %{rates: rates} = rate} = Forex.latest_rates(use_cache: false)

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "returns error tuple when feed is not available" do
      assert Forex.latest_rates(
               feed_fn: {Forex.FeedMock, :get_latest_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "supports different base currencies" do
      {:ok, %{rates: eur_rates}} = Forex.latest_rates()
      {:ok, %{rates: usd_rates}} = Forex.latest_rates(base: "USD")

      refute eur_rates == usd_rates
      assert Decimal.eq?(usd_rates[:usd], Decimal.new(1))
    end

    test "supports string format" do
      {:ok, %{rates: rates}} = Forex.latest_rates(format: :string)

      assert is_binary(rates[:usd])
    end

    test "respects rounding option" do
      {:ok, %{rates: rates}} = Forex.latest_rates(round: 2)

      decimal_places =
        rates[:usd]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert decimal_places == 2
    end

    test "supports filtering of currency codes" do
      {:ok, %{rates: rates}} = Forex.latest_rates(symbols: [:usd, :gbp])

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert Map.has_key?(rates, :gbp)
      assert Map.keys(rates) |> length() == 2
      assert Enum.sort(Map.keys(rates)) == [:gbp, :usd]
    end

    test "empty symbols option returns all rates" do
      {:ok, %{rates: rates}} = Forex.latest_rates(symbols: [])

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert Map.has_key?(rates, :gbp)
      assert Map.keys(rates) |> length() == 31
    end
  end

  describe "latest_rates!/0" do
    test "returns latest exchange rates" do
      %{rates: rates} = rate = Forex.latest_rates!()

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "raises when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.latest_rates!(
          feed_fn: {Forex.FeedMock, :get_latest_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end
  end

  describe "last_ninety_days_rates/0" do
    test "returns rates for the last 90 days" do
      {:ok, [rate | _] = rates} = Forex.last_ninety_days_rates()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "returns error tuple when feed is not available" do
      assert Forex.last_ninety_days_rates(
               feed_fn: {Forex.FeedMock, :get_last_ninety_days_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} = Forex.last_ninety_days_rates()
      {:ok, [usd_rate | _] = usd_rates} = Forex.last_ninety_days_rates(base: "USD")

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "supports string format" do
      {:ok, [rate | _] = rates} = Forex.last_ninety_days_rates(format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:gbp])
    end

    test "respects rounding option" do
      {:ok, [rate | _] = rates} = Forex.last_ninety_days_rates(round: 2)

      decimal_places =
        rate.rates[:gbp]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert is_list(rates)
      assert decimal_places == 2
    end
  end

  describe "last_ninety_days_rates!/0" do
    test "returns rates for the last 90 days" do
      [rate | _] = rates = Forex.last_ninety_days_rates!()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:gbp)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:gbp)
    end

    test "raises when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.last_ninety_days_rates!(
          feed_fn: {Forex.FeedMock, :get_last_ninety_days_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end

    test "supports different base currencies" do
      [eur_rate | _] = eur_rates = Forex.last_ninety_days_rates!()
      [rate | _] = rates = Forex.last_ninety_days_rates!(base: :gbp)

      refute eur_rates == rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(rate.rates[:gbp], Decimal.new(1))
    end
  end

  describe "historic_rates/0" do
    test "returns all existing historic rates" do
      {:ok, [rate | _] = rates} = Forex.historic_rates()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "returns error tuple when feed is not available" do
      assert Forex.historic_rates(
               feed_fn: {Forex.FeedMock, :get_historic_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} = Forex.historic_rates()
      {:ok, [usd_rate | _] = usd_rates} = Forex.historic_rates(base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "supports string format" do
      {:ok, [rate | _] = rates} = Forex.historic_rates(format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:usd])
    end

    test "respects rounding option" do
      {:ok, [rate | _] = rates} = Forex.historic_rates(round: 2)

      decimal_places =
        rate.rates[:usd]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert is_list(rates)
      assert decimal_places == 2
    end
  end

  describe "historic_rates!/0" do
    test "returns all existing historic rates" do
      [rate | _] = rates = Forex.historic_rates!()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "raises when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.historic_rates!(
          feed_fn: {Forex.FeedMock, :get_historic_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end

    test "supports different base currencies" do
      [eur_rate | _] = eur_rates = Forex.historic_rates!()
      [rate | _] = rates = Forex.historic_rates!(base: :usd)

      refute eur_rates == rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(rate.rates[:usd], Decimal.new(1))
    end
  end

  describe "get_historic_rate/1" do
    test "returns historic rates for a specific date" do
      {:ok, rate} = Forex.get_historic_rate(~D[2024-10-25])
      {:ok, rate_from_string} = Forex.get_historic_rate("2024-10-25")

      assert %Forex{} = rate
      assert Map.has_key?(rate.rates, :usd)
      assert %Decimal{} = rate.rates[:usd]

      assert rate == rate_from_string
    end

    test "returns error for non-existing dates" do
      assert {:error, {Forex.FeedError, "Rate not found for date: 1982-02-25"}} ==
               Forex.get_historic_rate(~D[1982-02-25])
    end

    test "supports different base currencies" do
      {:ok, eur_rate} = Forex.get_historic_rate(~D[2024-10-25])
      {:ok, usd_rate} = Forex.get_historic_rate(~D[2024-10-25], base: :usd)

      refute eur_rate == usd_rate
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "supports string format" do
      {:ok, rate} = Forex.get_historic_rate(~D[2024-10-25], format: :string)
      assert is_binary(rate.rates[:usd])
    end

    test "respects rounding option" do
      {:ok, rate} = Forex.get_historic_rate(~D[2024-10-25], round: 2)

      decimal_places =
        rate.rates[:usd]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert decimal_places == 2
    end

    test "returns error tuple on invalid date" do
      assert Forex.get_historic_rate("invalid-date") == {:error, :invalid_date}
    end

    test "returns error tuple when feed is not available" do
      assert Forex.get_historic_rate(
               ~D[2024-10-25],
               feed_fn: {Forex.FeedMock, :get_historic_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end
  end

  describe "get_historic_rate!/1" do
    test "returns historic rates for a specific date" do
      rate = Forex.get_historic_rate!(~D[2024-10-25])
      rate_from_string = Forex.get_historic_rate!("2024-10-25")

      assert %Forex{} = rate
      assert Map.has_key?(rate.rates, :usd)
      assert %Decimal{} = rate.rates[:usd]
      assert rate == rate_from_string
    end

    test "supports different base currencies" do
      eur_rate = Forex.get_historic_rate!(~D[2024-10-25])
      usd_rate = Forex.get_historic_rate!(~D[2024-10-25], base: :usd)

      refute eur_rate == usd_rate
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "raises on non-existing dates" do
      assert_raise Forex.FeedError, fn ->
        Forex.get_historic_rate!(~D[1982-02-25])
      end
    end

    test "raises on invalid date" do
      assert_raise Forex.DateError, fn ->
        Forex.get_historic_rate!("invalid-date")
      end
    end
  end

  describe "get_historic_rates_between/2" do
    test "returns historic rates for a date range" do
      date_range = Date.range(~D[2024-10-25], ~D[2024-10-30])

      {:ok, [rate | _] = rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30])

      last_rate = List.last(rates)

      {:ok, rates_from_string} = Forex.get_historic_rates_between("2024-10-25", "2024-10-30")

      assert is_list(rates)

      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)

      assert Map.has_key?(last_rate, :date)
      assert Map.has_key?(last_rate, :rates)
      assert Map.get(last_rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(last_rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(last_rate, :rates) |> Map.get(:usd)

      assert rates == rates_from_string
      assert rate == List.first(rates_from_string)
      assert last_rate == List.last(rates_from_string)

      assert Enum.map(rates, fn r -> r.date in date_range end) |> Enum.all?()
    end

    test "supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30])

      {:ok, [usd_rate | _] = usd_rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30], base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "supports string format" do
      {:ok, [rate | _] = rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30], format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:usd])
    end
  end

  describe "get_historic_rates_between!/2" do
    test "returns historic rates for a date range" do
      date_range = Date.range(~D[2024-10-25], ~D[2024-10-30])

      [rate | _] = rates = Forex.get_historic_rates_between!(~D[2024-10-25], ~D[2024-10-30])
      last_rate = List.last(rates)

      rates_from_string = Forex.get_historic_rates_between!("2024-10-25", "2024-10-30")

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)

      assert rates == rates_from_string
      assert rate == List.first(rates_from_string)
      assert last_rate == List.last(rates_from_string)

      assert Enum.map(rates, fn r -> r.date in date_range end) |> Enum.all?()
    end

    test "raises DateError on invalid date strings" do
      assert_raise Forex.DateError, fn ->
        Forex.get_historic_rates_between!("not-a-date", "also-not-a-date")
      end
    end
  end

  describe "last_updated/0" do
    test "returns the last updated date" do
      # Ensure the cache has been populated first
      Forex.latest_rates()
      Forex.last_ninety_days_rates()

      last_updated = Forex.last_updated()

      assert is_list(last_updated)
      assert Keyword.has_key?(last_updated, :latest_rates)
      assert Keyword.has_key?(last_updated, :last_ninety_days_rates)
    end
  end

  describe "exchange/4" do
    test "converts between currencies" do
      assert {:ok, amount} = Forex.exchange(100, "EUR", :usd)
      assert %Decimal{} = amount
      assert Decimal.gt?(amount, Decimal.new(0))
    end

    test "handles different amount formats" do
      assert {:ok, _} = Forex.exchange(100, "EUR", "USD")
      assert {:ok, _} = Forex.exchange(100.50, "EUR", "USD")
      assert {:ok, _} = Forex.exchange("100", "EUR", "USD")
      assert {:ok, _} = Forex.exchange("100.50", "EUR", "USD")
    end

    test "validates currency codes" do
      assert {:error, _} = Forex.exchange(100, "INVALID", "USD")
      assert {:error, _} = Forex.exchange(100, "EUR", "INVALID")
    end

    test "converts to EUR correctly" do
      assert {:ok, usd_to_eur} = Forex.exchange(100, "USD", "EUR")
      assert %Decimal{} = usd_to_eur
      assert Decimal.gt?(usd_to_eur, Decimal.new(0))
      refute Decimal.eq?(usd_to_eur, Decimal.new("1.00000"))

      assert {:ok, gbp_to_eur} = Forex.exchange(100, "GBP", "EUR")
      assert %Decimal{} = gbp_to_eur
      assert Decimal.gt?(gbp_to_eur, Decimal.new(0))
      refute Decimal.eq?(gbp_to_eur, Decimal.new("1.00000"))
    end

    test "converting to EUR and back approximates original amount" do
      {:ok, eur_amount} = Forex.exchange(100, "USD", "EUR")
      {:ok, usd_amount} = Forex.exchange(100, "EUR", "USD")

      # USD -> EUR -> USD should round-trip close to 100
      {:ok, round_tripped} = Forex.exchange(1, "EUR", "USD")

      # EUR/USD * USD/EUR should be close to 1
      product = Decimal.mult(eur_amount, usd_amount) |> Decimal.div(Decimal.new(10_000))
      assert Decimal.lt?(Decimal.abs(Decimal.sub(product, Decimal.new(1))), Decimal.new("0.01"))

      # The EUR/USD rate should be the reciprocal of USD/EUR
      refute Decimal.eq?(round_tripped, Decimal.new("1.00000"))
    end

    test "EUR to EUR returns the same amount" do
      assert {:ok, amount} = Forex.exchange(100, "EUR", "EUR")
      assert Decimal.eq?(amount, Decimal.new(100))
    end
  end

  describe "exchange!/4" do
    test "returns the converted amount on success" do
      result = Forex.exchange!(100, "EUR", :usd)
      assert %Decimal{} = result
      assert Decimal.gt?(result, Decimal.new(0))
    end

    test "raises on invalid currencies" do
      assert_raise Forex.CurrencyError, fn ->
        Forex.exchange!(100, "INVALID", "USD")
      end
    end
  end

  describe "exchange_historic_rate/5" do
    test "exchanges an amount between currencies at a specific historic date" do
      assert {:ok, result} = Forex.exchange_historic_rate(~D[2024-10-25], 100, :eur, :usd)
      assert %Decimal{} = result
      assert Decimal.gt?(result, Decimal.new(0))
    end

    test "accepts a date string" do
      assert {:ok, result} = Forex.exchange_historic_rate("2024-10-25", 100, :eur, :usd)
      assert %Decimal{} = result
    end

    test "returns error when date is not found" do
      assert {:error, _} = Forex.exchange_historic_rate(~D[1982-02-25], 100, :eur, :usd)
    end

    test "returns error when feed is not available" do
      assert {:error, "Feed API Error"} =
               Forex.exchange_historic_rate(
                 ~D[2024-10-25],
                 100,
                 :eur,
                 :usd,
                 feed_fn: {Forex.FeedMock, :get_historic_rates, [[type: :error]]},
                 use_cache: false
               )
    end
  end

  describe "exchange_historic_rate!/5" do
    test "exchanges an amount between currencies at a specific historic date" do
      result = Forex.exchange_historic_rate!(~D[2024-10-25], 100, :eur, :usd)
      assert %Decimal{} = result
      assert Decimal.gt?(result, Decimal.new(0))
    end

    test "accepts a date string" do
      result = Forex.exchange_historic_rate!("2024-10-25", 100, :eur, :usd)
      assert %Decimal{} = result
    end

    test "raises FeedError when date is not found" do
      assert_raise Forex.FeedError, fn ->
        Forex.exchange_historic_rate!(~D[1982-02-25], 100, :eur, :usd)
      end
    end

    test "raises FeedError when feed is not available" do
      assert_raise Forex.FeedError, fn ->
        Forex.exchange_historic_rate!(
          ~D[2024-10-25],
          100,
          :eur,
          :usd,
          feed_fn: {Forex.FeedMock, :get_historic_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end
  end

  describe "exchange_rates/5 via Forex.Currency" do
    test "successfully converts between currencies given a list of rates" do
      rates = single_forex_fixture()

      assert {:ok, "1.00000"} ==
               Forex.Currency.exchange_rates(rates, 1, :eur, :eur, format: :string)

      assert {:ok, "1.20210"} ==
               Forex.Currency.exchange_rates(rates, 1, :gbp, :eur, format: :string)
    end

    test "accepts format and rounding options" do
      rates = single_forex_fixture()

      assert {:ok, result} =
               Forex.Currency.exchange_rates(rates, 1, :eur, :usd, format: :string, round: 2)

      assert is_binary(result)
      assert String.match?(result, ~r/^\d+\.\d{2}$/)
    end

    test "accepts atom currency codes" do
      rates = single_forex_fixture()
      assert {:ok, _} = Forex.Currency.exchange_rates(rates, 1, :EUR, :USD)
    end

    test "returns an error if the currency with the given iso code does not exist" do
      rates = single_forex_fixture()
      assert {:error, :invalid_currency} == Forex.Currency.exchange_rates(rates, 1, :eur, :xyz)
    end
  end

  describe "exchange_rates!/4 via Forex.Currency" do
    test "successfully converts between currencies given a list of rates" do
      rates = single_forex_fixture()

      assert Decimal.eq?(
               Forex.Currency.exchange_rates!(rates, 1, :eur, :eur),
               Decimal.new("1.00000")
             )

      assert Decimal.eq?(
               Forex.Currency.exchange_rates!(rates, 1, :gbp, :eur),
               Decimal.new("1.20210")
             )
    end

    test "raises an error on invalid exchanges" do
      rates = single_forex_fixture()

      assert_raise Forex.CurrencyError, fn ->
        Forex.Currency.exchange_rates!(rates, nil, :eur, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Forex.Currency.exchange_rates!(rates, [], :eur, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Forex.Currency.exchange_rates!(rates, 1, nil, :usd)
      end

      assert_raise Forex.CurrencyError, fn ->
        Forex.Currency.exchange_rates!(rates, 1, [], :usd)
      end
    end

    test "raises an error if the currency with the given iso code does not exist" do
      rates = single_forex_fixture()

      assert_raise Forex.CurrencyError, fn ->
        Forex.Currency.exchange_rates!(rates, 1, :eur, :xyz)
      end
    end
  end
end
