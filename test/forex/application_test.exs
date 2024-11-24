defmodule Forex.ApplicationTest do
  use ExUnit.Case

  test "the application supervisor starts with the correct options" do
    Application.ensure_started(:forex)

    {_app, options} =
      Application.spec(:forex)
      |> Keyword.get(:mod)

    assert options == [strategy: :one_for_one, name: Forex.Supervisor]
  end

  test "the application supervisor starts the fetcher supervisor" do
    Application.ensure_started(:forex)

    process_info =
      Process.whereis(Forex.Fetcher.Supervisor)
      |> Process.info()

    assert process_info[:registered_name] == Forex.Fetcher.Supervisor
  end
end
