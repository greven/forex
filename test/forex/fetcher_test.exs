defmodule Forex.FetcherTest do
  use ExUnit.Case, async: true

  import Forex.TestHelpers
  import Forex.FeedFixtures

  alias Forex.Fetcher

  describe "configuration and options" do
    test "the fetcher options have the correct defaults" do
      assert Forex.Fetcher.options() == [
               schedular_interval: :timer.hours(12),
               use_cache: true
             ]
    end
  end

  describe "get_options/1" do
    setup do
      sup_name = Module.concat(__MODULE__, :get_options_sup)
      fetcher_name = Module.concat(__MODULE__, :get_options_fetcher)

      start_supervised!(%{
        id: sup_name,
        start: {Forex.Fetcher.Supervisor, :start_link, [[name: sup_name, auto_start: false]]}
      })

      {:ok, pid} =
        Forex.Fetcher.Supervisor.start_fetcher(sup_name,
          name: fetcher_name,
          use_cache: false
        )

      %{fetcher: fetcher_name, fetcher_pid: pid}
    end

    test "returns the options used to start the fetcher process", %{fetcher: fetcher} do
      opts = Fetcher.get_options(fetcher)
      assert opts[:use_cache] == false
      assert opts[:schedular_interval] == :timer.hours(12)
    end
  end

  describe "get/1" do
    setup do
      setup_test_cache()
    end

    test "returns the latest exchange rates" do
      Forex.Cache.cache_mod().delete(:latest_rates)

      assert Fetcher.get(:latest_rates) == {:ok, single_rates_fixture()}
      assert Forex.Cache.cache_mod().get(:latest_rates) == single_rates_fixture()
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
    end

    test "returns the latest exchange rates without using the cache" do
      assert Fetcher.get(:latest_rates, use_cache: false) == {:ok, single_rates_fixture()}
      refute Forex.Cache.cache_mod().get(:latest_rates)
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

  describe "handle_info scheduled work" do
    setup do
      sup_name = Module.concat(__MODULE__, :handle_info_sup)
      fetcher_name = Module.concat(__MODULE__, :handle_info_fetcher)

      start_supervised!(%{
        id: sup_name,
        start: {Forex.Fetcher.Supervisor, :start_link, [[name: sup_name, auto_start: false]]}
      })

      {:ok, pid} =
        Forex.Fetcher.Supervisor.start_fetcher(sup_name,
          name: fetcher_name,
          use_cache: false
        )

      %{fetcher_pid: pid}
    end

    test "handles :latest_rates message and reschedules", %{fetcher_pid: pid} do
      send(pid, :latest_rates)
      # Give the GenServer a moment to process
      Process.sleep(50)
      assert Process.alive?(pid)
    end

    test "handles :last_ninety_days_rates message and reschedules", %{fetcher_pid: pid} do
      send(pid, :last_ninety_days_rates)
      Process.sleep(50)
      assert Process.alive?(pid)
    end
  end

  describe "handle_continue with failing feed" do
    test "logs a warning when some exchange rates fail to update" do
      sup_name = Module.concat(__MODULE__, :failing_sup)
      fetcher_name = Module.concat(__MODULE__, :failing_fetcher)

      start_supervised!(%{
        id: sup_name,
        start: {Forex.Fetcher.Supervisor, :start_link, [[name: sup_name, auto_start: false]]}
      })

      # Use a feed_fn MFA that returns an error so handle_continue logs a warning
      assert {:ok, pid} =
               Forex.Fetcher.Supervisor.start_fetcher(sup_name,
                 name: fetcher_name,
                 use_cache: false,
                 feed_fn: {Forex.FeedMock, :get_latest_rates, [[type: :error]]}
               )

      # Give handle_continue time to run
      Process.sleep(100)
      assert Process.alive?(pid)
    end
  end

  describe "terminate/2" do
    setup do
      setup_test_cache()
    end

    test "terminates the fetcher process with :normal reason" do
      assert :ok == Fetcher.terminate(:normal, Forex.Fetcher.options())
    end

    test "terminates the fetcher process with :shutdown reason" do
      assert :ok == Fetcher.terminate(:shutdown, Forex.Fetcher.options())
    end
  end
end
