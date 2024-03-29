defmodule Forex.Fetcher.Supervisor do
  @moduledoc """
  The `Forex.Fetcher.Supervisor` module is responsible for supervising the `Forex.Fetcher`
  process, .ie., starting, stopping, and restarting the process.
  """

  use Supervisor

  alias Forex.Fetcher

  @doc false
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    if Fetcher.options()[:auto_start], do: Fetcher.start()
  end

  @doc false
  def init(opts) do
    Supervisor.init(opts, strategy: :one_for_one)
  end

  @doc false
  def stop do
    Supervisor.stop(__MODULE__)
  end

  def start_fetcher(opts \\ Fetcher.options()) do
    Supervisor.start_child(__MODULE__, fetcher_spec(opts))
  end

  defp fetcher_spec(opts) do
    %{
      id: Fetcher,
      start: {Fetcher, :start_link, [opts]},
    }
  end

  def stop_fetcher do
    Supervisor.terminate_child(__MODULE__, Fetcher)
  end

  def restart_fetcher do
    Supervisor.restart_child(__MODULE__, Fetcher)
  end
end
