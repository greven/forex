defmodule Forex.TestHelpers do
  @moduledoc """
  Shared test helpers for the Forex test suite.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Initialises the configured cache module for the current test process
  and registers a cleanup callback to terminate it when the test finishes.

  When using `Forex.CacheMock` (the default in the test environment), the
  cache is backed by the process dictionary, so each test process starts
  with a clean slate automatically. This helper still calls `init/0` for
  completeness and future-proofs against other cache implementations.
  """
  def setup_test_cache do
    Forex.Cache.cache_mod().init()
    on_exit(fn -> Forex.Cache.cache_mod().terminate() end)

    :ok
  end
end
