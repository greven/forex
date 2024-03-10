defmodule Forex do
  @moduledoc """
  `Forex` is a simple Elixir library that serves as a wrapper to the
  foreign exchange reference rates provided by the European Central Bank.

  ## Motivation

  Even though there are other libraries in the Elixir ecosystem that provide
  similar functionality (example: `ex_money`), `Forex` was created with the intent
  of providing access to currency exchange rates, for projects that want to self-host
  the data and not rely on third-party paid services in a simple and straightforward
  manner.

  ## Usage

  ```elixir
  iex> Forex.current_rates()
  {:ok, [
    %{currency: "USD", rate: "1.1234"},
    %{currency: "JPY", rate: "120.1234"},
    ...
  ]}
  ```
  """
end
