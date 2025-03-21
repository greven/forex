defmodule Forex.Support.TestHelpers do
  @moduledoc """
  Helper functions for setting up tests in the Forex application.
  """

  @doc """
  Configure tests to use a mock cache module.
  """
  def setup_test_cache do
    cache_module = Application.get_env(:forex, :cache_module)
    Application.put_env(:forex, :cache_module, Forex.Support.CacheMock)

    ExUnit.Callbacks.on_exit(fn ->
      if cache_module do
        Application.put_env(:forex, :cache_module, cache_module)
      else
        Application.delete_env(:forex, :cache_module)
      end
    end)
  end
end
