defmodule Forex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, args) do
    children = [
      Forex.Fetcher.Supervisor
    ]

    opts =
      if args == [],
        do: [strategy: :one_for_one, name: Forex.Supervisor],
        else: args

    Supervisor.start_link(children, opts)
  end
end
