defmodule Forex.SupportTest do
  use ExUnit.Case, async: true
  doctest Forex.Support

  # test "cache_memory_usage/1" do
  #   start_link_supervised!(Forex.Supervisor)

  #   assert Forex.Support.cache_memory_usage(:ets) |> String.contains?("MB")
  # end
end
