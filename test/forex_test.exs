defmodule ForexTest do
  use ExUnit.Case
  doctest Forex

  test "greets the world" do
    assert Forex.hello() == :world
  end
end
