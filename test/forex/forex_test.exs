defmodule ForexTest do
  use ExUnit.Case

  setup_all do
    start_supervised!(Forex.Supervisor)

    :ok
  end

  describe "supervisor and config" do
    test "returns the default options" do
      assert Forex.Supervisor.options() == %{auto_start: true}
    end

    test "returns the options passed as arguments" do
      assert Forex.Supervisor.options(auto_start: false) == %{auto_start: false}
    end

    test "json_library/0 returns the configured JSON library" do
      assert Forex.json_library() == JSON
    end

    test "starts the fetcher process" do
      fetcher_supervisor_pid = Process.whereis(Forex.Supervisor)
      fetcher_pid = Process.whereis(Forex.Fetcher)

      assert Process.alive?(fetcher_supervisor_pid)
      assert Process.alive?(fetcher_pid)
      assert Forex.Supervisor.fetcher_initiated?()
      assert Forex.Supervisor.fetcher_status() == :running
      assert Forex.Supervisor.start_fetcher() == {:error, {:already_started, fetcher_pid}}
    end

    test "starts the fetcher process with the correct options" do
      fetcher_pid = Process.whereis(Forex.Fetcher)

      assert :sys.get_state(fetcher_pid) == %{
               cache_module: Forex.Cache.ETS,
               schedular_interval: :timer.hours(12),
               use_cache: true
             }

      assert Forex.Cache.cache_mod() == Forex.Cache.ETS
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

  describe "exchange rates" do
    test "latest_rates/0 returns latest exchange rates" do
      {:ok, %{rates: rates} = rate} = Forex.latest_rates()

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "latest_rates/0 returns rates without using the cache" do
      {:ok, %{rates: rates} = rate} = Forex.latest_rates(use_cache: false)

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "latest_rates/0 returns error tuple when feed is not available" do
      assert Forex.latest_rates(
               feed_fn: {Forex.FeedAPIMock, :get_latest_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "latest_rates/1 supports different base currencies" do
      {:ok, %{rates: eur_rates}} = Forex.latest_rates()
      {:ok, %{rates: usd_rates}} = Forex.latest_rates(base: "USD")

      refute eur_rates == usd_rates
      assert Decimal.eq?(usd_rates[:usd], Decimal.new(1))
    end

    test "latest_rates/1 supports string format" do
      {:ok, %{rates: rates}} = Forex.latest_rates(format: :string)

      assert is_binary(rates[:usd])
    end

    test "latest_rates/1 respects rounding option" do
      {:ok, %{rates: rates}} = Forex.latest_rates(round: 2)

      decimal_places =
        rates[:usd]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert decimal_places == 2
    end

    test "latest_rates/1 supports filtering of currency codes" do
      {:ok, %{rates: rates}} = Forex.latest_rates(symbols: [:usd, :gbp])

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert Map.has_key?(rates, :gbp)
      assert Map.keys(rates) |> length() == 2
      assert Enum.sort(Map.keys(rates)) == [:gbp, :usd]
    end

    test "latest_rates/1 empty symbols option returns all rates" do
      {:ok, %{rates: rates}} = Forex.latest_rates(symbols: [])

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert Map.has_key?(rates, :gbp)
      assert Map.keys(rates) |> length() == 31
    end

    test "latest_rates!/0 returns latest exchange rates" do
      %{rates: rates} = rate = Forex.latest_rates!()

      assert is_map(rate)
      assert is_map(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = Map.get(rates, :usd)
    end

    test "latest_rates!/0 returns error tuple when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.latest_rates!(
          feed_fn: {Forex.FeedAPIMock, :get_latest_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end

    test "last_ninety_days_rates/0 returns rates for the last 90 days" do
      {:ok, [rate | _] = rates} = Forex.last_ninety_days_rates()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "last_ninety_days_rates/0 returns error tuple when feed is not available" do
      assert Forex.last_ninety_days_rates(
               feed_fn: {Forex.FeedAPIMock, :get_last_ninety_days_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "last_ninety_days_rates/1 supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} = Forex.last_ninety_days_rates()
      {:ok, [usd_rate | _] = usd_rates} = Forex.last_ninety_days_rates(base: "USD")

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "last_ninety_days_rates/1 supports string format" do
      {:ok, [rate | _] = rates} = Forex.last_ninety_days_rates(format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:gbp])
    end

    test "last_ninety_days_rates/1 respects rounding option" do
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

    test "last_ninety_days_rates!/0 returns rates for the last 90 days" do
      [rate | _] = rates = Forex.last_ninety_days_rates!()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:gbp)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:gbp)
    end

    test "last_ninety_days_rates!/0 returns error tuple when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.last_ninety_days_rates!(
          feed_fn: {Forex.FeedAPIMock, :get_last_ninety_days_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end

    test "last_ninety_days_rates!/1 supports different base currencies" do
      [eur_rate | _] = eur_rates = Forex.last_ninety_days_rates!()
      [rate | _] = rates = Forex.last_ninety_days_rates!(base: :gbp)

      refute eur_rates == rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(rate.rates[:gbp], Decimal.new(1))
    end

    test "historic_rates/0 returns all existing historic rates" do
      {:ok, [rate | _] = rates} = Forex.historic_rates()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "historic_rates/0 returns error tuple when feed is not available" do
      assert Forex.historic_rates(
               feed_fn: {Forex.FeedAPIMock, :get_historic_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "historic_rates/1 supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} = Forex.historic_rates()
      {:ok, [usd_rate | _] = usd_rates} = Forex.historic_rates(base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "historic_rates/1 supports string format" do
      {:ok, [rate | _] = rates} = Forex.historic_rates(format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:usd])
    end

    test "historic_rates/1 respects rounding option" do
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

    test "historic_rates!/0 returns all existing historic rates" do
      [rate | _] = rates = Forex.historic_rates!()

      assert is_list(rates)
      assert Map.has_key?(rate, :date)
      assert Map.has_key?(rate, :rates)
      assert Map.get(rate, :rates) |> Map.has_key?(:usd)
      assert Map.get(rate, :rates) |> Map.keys() |> length() == 31
      assert %Decimal{} = Map.get(rate, :rates) |> Map.get(:usd)
    end

    test "historic_rates!/0 returns error tuple when feed is not available" do
      assert_raise RuntimeError, fn ->
        Forex.historic_rates!(
          feed_fn: {Forex.FeedAPIMock, :get_historic_rates, [[type: :error]]},
          use_cache: false
        )
      end
    end

    test "historic_rates!/1 supports different base currencies" do
      [eur_rate | _] = eur_rates = Forex.historic_rates!()
      [rate | _] = rates = Forex.historic_rates!(base: :usd)

      refute eur_rates == rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(rate.rates[:usd], Decimal.new(1))
    end

    test "get_historic_rate/1 returns historic rates for a specific date" do
      {:ok, rates} = Forex.get_historic_rate(~D[2024-10-25])
      {:ok, rates_from_string} = Forex.get_historic_rate("2024-10-25")

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = rates[:usd]

      assert rates == rates_from_string
    end

    test "get_historic_rate/1 returns nil for non-existing dates" do
      assert {:error, {Forex.DateError, "Rate not found for date: 1982-02-25"}} ==
               Forex.get_historic_rate(~D[1982-02-25])
    end

    test "get_historic_rate/1 supports different base currencies" do
      {:ok, eur_rates} = Forex.get_historic_rate(~D[2024-10-25])
      {:ok, usd_rates} = Forex.get_historic_rate(~D[2024-10-25], base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(usd_rates[:usd], Decimal.new(1))
    end

    test "get_historic_rate/1 supports string format" do
      {:ok, rates} = Forex.get_historic_rate(~D[2024-10-25], format: :string)
      assert is_binary(rates[:usd])
    end

    test "get_historic_rate/1 respects rounding option" do
      {:ok, rates} = Forex.get_historic_rate(~D[2024-10-25], round: 2)

      decimal_places =
        rates[:usd]
        |> Decimal.to_string()
        |> String.split(".")
        |> List.last()
        |> String.length()

      assert decimal_places == 2
    end

    test "get_historic_rate/1 returns error tuple on invalid date" do
      assert Forex.get_historic_rate("invalid-date") == {:error, :invalid_date}
    end

    test "get_historic_rate/1 returns error tuple when feed is not available" do
      assert Forex.get_historic_rate(
               ~D[2024-10-25],
               feed_fn: {Forex.FeedAPIMock, :get_historic_rates, [[type: :error]]},
               use_cache: false
             ) == {:error, "Feed API Error"}
    end

    test "get_historic_rate!/1 returns historic rates for a specific date" do
      rates = Forex.get_historic_rate!(~D[2024-10-25])
      rates_from_string = Forex.get_historic_rate!("2024-10-25")

      assert is_map(rates)
      assert Map.has_key?(rates, :usd)
      assert %Decimal{} = rates[:usd]
      assert rates == rates_from_string
    end

    test "get_historic_rate!/1 supports different base currencies" do
      eur_rates = Forex.get_historic_rate!(~D[2024-10-25])
      usd_rates = Forex.get_historic_rate!(~D[2024-10-25], base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(usd_rates[:usd], Decimal.new(1))
    end

    test "get_historic_rate!/1 raises on non-existing dates" do
      assert_raise Forex.FeedError, fn ->
        Forex.get_historic_rate!(~D[1982-02-25])
      end
    end

    test "get_historic_rate!/1 raises on invalid date" do
      assert_raise Forex.DateError, fn ->
        Forex.get_historic_rate!("invalid-date")
      end
    end

    test "get_historic_rates_between/2 returns historic rates for a date range" do
      date_range = Date.range(~D[2024-10-25], ~D[2024-10-30])

      {:ok, [rate | _] = rates} = Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30])
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

    test "get_historic_rates_between/3 supports different base currencies" do
      {:ok, [eur_rate | _] = eur_rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30])

      {:ok, [usd_rate | _] = usd_rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30], base: :usd)

      refute eur_rates == usd_rates
      assert Decimal.eq?(eur_rate.rates[:eur], Decimal.new(1))
      assert Decimal.eq?(usd_rate.rates[:usd], Decimal.new(1))
    end

    test "get_historic_rates_between/3 supports string format" do
      {:ok, [rate | _] = rates} =
        Forex.get_historic_rates_between(~D[2024-10-25], ~D[2024-10-30], format: :string)

      assert is_list(rates)
      assert is_binary(rate.rates[:usd])
    end

    test "get_historic_rates_between!/2 returns historic rates for a date range" do
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
  end

  describe "last_updated/0" do
    test "returns the last updated date" do
      last_updated = Forex.last_updated()

      assert is_list(last_updated)
      assert Keyword.has_key?(last_updated, :latest_rates)
      assert Keyword.has_key?(last_updated, :last_ninety_days_rates)
    end
  end

  describe "currency exchange" do
    test "exchange/4 converts between currencies" do
      assert {:ok, amount} = Forex.exchange(100, "EUR", :usd)
      assert %Decimal{} = amount
      assert Decimal.gt?(amount, Decimal.new(0))
    end

    test "exchange/4 handles different amount formats" do
      assert {:ok, _} = Forex.exchange(100, "EUR", "USD")
      assert {:ok, _} = Forex.exchange(100.50, "EUR", "USD")
      assert {:ok, _} = Forex.exchange("100", "EUR", "USD")
      assert {:ok, _} = Forex.exchange("100.50", "EUR", "USD")
    end

    test "exchange!/4 raises on invalid currencies" do
      assert_raise Forex.CurrencyError, fn ->
        Forex.exchange!(100, "INVALID", "USD")
      end
    end
  end

  describe "error handling" do
    test "validates currency codes" do
      assert {:error, _} = Forex.exchange(100, "INVALID", "USD")
      assert {:error, _} = Forex.exchange(100, "EUR", "INVALID")
    end
  end
end
