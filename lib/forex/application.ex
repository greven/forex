defmodule Forex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, args) do
    start_api? = Application.get_env(:forex, :start_api, false)

    children = [
      Forex.Fetcher.Supervisor
    ]

    children =
      if start_api?,
        do: [ForexAPI.Endpoint | children],
        else: children

    opts =
      if args == [],
        do: [strategy: :one_for_one, name: Forex.Supervisor],
        else: args

    Supervisor.start_link(children, opts)
  end
end
