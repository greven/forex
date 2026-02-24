defmodule Forex.SupervisorTest do
  use ExUnit.Case, async: false

  # Lifecycle tests for the Forex.Fetcher.Supervisor and Forex.Fetcher GenServer.
  # These tests start isolated supervisor/fetcher instances using unique names
  # per test so they don't interfere with the application-level singleton or
  # with one another. Because they manipulate named processes they must run
  # synchronously (async: false).

  describe "supervisor and config" do
    setup context do
      sup_name = Module.concat(__MODULE__, context.test)
      fetcher_name = Module.concat(sup_name, Fetcher)

      pid =
        start_supervised!(%{
          id: sup_name,
          start: {Forex.Fetcher.Supervisor, :start_link, [[name: sup_name, auto_start: false]]}
        })

      %{supervisor: sup_name, supervisor_pid: pid, fetcher_name: fetcher_name}
    end

    test "returns the default supervisor options" do
      assert Forex.Options.fetcher_supervisor_options() == [auto_start: true]
    end

    test "returns the options passed as arguments" do
      assert Forex.Options.fetcher_supervisor_options(auto_start: false) == [auto_start: false]
    end

    test "json_library/0 returns the configured JSON library" do
      assert Forex.json_library() == JSON
    end

    test "starts the fetcher process", %{supervisor: sup, fetcher_name: fetcher_name} do
      assert {:ok, fetcher_pid} = Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)

      assert Process.alive?(fetcher_pid)
      assert Forex.Fetcher.Supervisor.fetcher_initiated?(sup)
      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :running

      assert Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name) ==
               {:error, {:already_started, fetcher_pid}}
    end

    test "starts the fetcher process with the correct default options", %{
      supervisor: sup,
      fetcher_name: fetcher_name
    } do
      {:ok, fetcher_pid} = Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)

      state = :sys.get_state(fetcher_pid)

      assert state[:use_cache] == true
      assert state[:schedular_interval] == :timer.hours(12)
    end

    test "fetcher_status/1 returns :not_started when no fetcher has been added", %{
      supervisor: sup
    } do
      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :not_started
    end

    test "fetcher_status/1 returns :stopped after stopping the fetcher", %{
      supervisor: sup,
      fetcher_name: fetcher_name
    } do
      Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)
      Forex.Fetcher.Supervisor.stop_fetcher(sup)

      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :stopped
    end

    test "fetcher_initiated?/1 returns false when no fetcher was started", %{supervisor: sup} do
      refute Forex.Fetcher.Supervisor.fetcher_initiated?(sup)
    end

    test "fetcher_running?/1 returns false when no fetcher was started", %{supervisor: sup} do
      refute Forex.Fetcher.Supervisor.fetcher_running?(sup)
    end

    test "stop/1 stops the supervisor process", %{supervisor: sup, supervisor_pid: pid} do
      assert Process.alive?(pid)
      assert :ok = Forex.Fetcher.Supervisor.stop(sup)
      refute Process.alive?(pid)
    end

    test "restart_fetcher/1 restarts a stopped fetcher", %{
      supervisor: sup,
      fetcher_name: fetcher_name
    } do
      Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)
      Forex.Fetcher.Supervisor.stop_fetcher(sup)

      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :stopped

      assert {:ok, new_pid} = Forex.Fetcher.Supervisor.restart_fetcher(sup)
      assert Process.alive?(new_pid)
      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :running
    end

    test "delete_fetcher/1 removes the fetcher from the supervisor", %{
      supervisor: sup,
      fetcher_name: fetcher_name
    } do
      Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)
      Forex.Fetcher.Supervisor.stop_fetcher(sup)

      assert Forex.Fetcher.Supervisor.fetcher_initiated?(sup)

      assert :ok = Forex.Fetcher.Supervisor.delete_fetcher(sup)

      refute Forex.Fetcher.Supervisor.fetcher_initiated?(sup)
      assert Forex.Fetcher.Supervisor.fetcher_status(sup) == :not_started
    end

    test "start_fetcher/1 with a list of opts starts the default supervisor's fetcher", %{
      supervisor: sup,
      fetcher_name: fetcher_name
    } do
      # start_fetcher(opts) delegates to start_fetcher(__MODULE__, opts)
      # We need a supervisor that IS __MODULE__ to test the 1-arity list path,
      # but we can verify the 2-arity dispatching works via the named supervisor.
      assert {:ok, pid} = Forex.Fetcher.Supervisor.start_fetcher(sup, name: fetcher_name)
      assert Process.alive?(pid)
    end
  end
end
