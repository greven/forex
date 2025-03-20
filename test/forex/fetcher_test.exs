defmodule Forex.FetcherTest do
  use ExUnit.Case, async: true

  import Forex.Support.TestHelpers
  import Forex.Support.FeedFixtures

  alias Forex.Fetcher

  describe "configuration and options" do
    setup do
      start_link_supervised!(Forex.Supervisor)

      :ok
    end

    test "the fetcher options have the correct defaults" do
      assert Forex.Fetcher.options() == %{
               cache_module: Forex.Cache.ETS,
               schedular_interval: :timer.hours(12),
               use_cache: true
             }
    end

    test "the fetcher supervisor starts the fetcher process" do
      fetcher_supervisor_pid = Process.whereis(Forex.Supervisor)
      fetcher_pid = Process.whereis(Forex.Fetcher)

      assert Process.alive?(fetcher_supervisor_pid)
      assert Process.alive?(fetcher_pid)
      assert Forex.Supervisor.fetcher_initiated?()
      assert Forex.Supervisor.fetcher_status() == :running
      assert Forex.Supervisor.start_fetcher() == {:error, {:already_started, fetcher_pid}}
    end

    test "the fetcher supervisor starts the fetcher process with the correct options" do
      fetcher_pid = Process.whereis(Forex.Fetcher)

      assert :sys.get_state(fetcher_pid) == %{
               cache_module: Forex.Cache.ETS,
               schedular_interval: :timer.hours(12),
               use_cache: true
             }

      assert Forex.Cache.cache_mod() == Forex.Cache.ETS
    end
  end

  describe "get/1" do
    setup do
      setup_test_cache()
      Forex.Cache.cache_mod().init()

      :ok
    end

    test "returns the current exchange rates" do
      Forex.Cache.cache_mod().delete(:current_rates)

      assert Fetcher.get(:current_rates) == {:ok, single_rate_fixture()}
      assert Forex.Cache.cache_mod().get(:current_rates) == single_rate_fixture()
    end

    test "returns the last ninety days exchange rates" do
      Forex.Cache.cache_mod().delete(:last_ninety_days_rates)

      assert Fetcher.get(:last_ninety_days_rates) == {:ok, multiple_rates_fixture()}
      assert Forex.Cache.cache_mod().get(:last_ninety_days_rates) == multiple_rates_fixture()
    end

    test "returns the historic exchange rates" do
      Forex.Cache.cache_mod().delete(:historic_rates)

      assert Fetcher.get(:historic_rates) == {:ok, multiple_rates_fixture()}
      assert Forex.Cache.cache_mod().get(:historic_rates) == multiple_rates_fixture()
    end
  end

  describe "get/2" do
    setup do
      setup_test_cache()
      Forex.Cache.cache_mod().init()

      :ok
    end

    test "returns the current exchange rates without using the cache" do
      assert Fetcher.get(:current_rates, use_cache: false) == {:ok, single_rate_fixture()}
      refute Forex.Cache.cache_mod().get(:current_rates)
    end

    test "returns the last ninety days exchange rates without using the cache" do
      assert Fetcher.get(:last_ninety_days_rates, use_cache: false) ==
               {:ok, multiple_rates_fixture()}

      refute Forex.Cache.cache_mod().get(:last_ninety_days_rates)
    end

    test "returns the historic exchange rates without using the cache" do
      assert Fetcher.get(:historic_rates, use_cache: false) == {:ok, multiple_rates_fixture()}
      refute Forex.Cache.cache_mod().get(:historic_rates)
    end
  end
end
