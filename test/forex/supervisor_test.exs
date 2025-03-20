defmodule Forex.FetcherSupervisorTest do
  use ExUnit.Case, async: true

  describe "options/1" do
    test "returns the default options" do
      assert Forex.Supervisor.options() == %{auto_start: true}
    end

    test "returns the options passed as arguments" do
      assert Forex.Supervisor.options(auto_start: false) == %{auto_start: false}
    end
  end
end
