defmodule Forex.Fetcher.Supervisor do
  @moduledoc """
  The `Forex.Fetcher.Supervisor` module is responsible for supervising the `Forex.Fetcher`
  process, .ie., starting, stopping, and restarting the process.

  The `Forex.Fetcher.Supervisor` accepts the following options:

  * `auto_start` - A boolean value that determines if the fetcher process should be started
    automatically when the supervisor is started. The default value is `true`.
  """

  use Supervisor

  alias Forex.Fetcher

  ##  Options

  defp options_schema do
    NimbleOptions.new!(
      auto_start: [
        type: :boolean,
        default: Application.get_env(:forex, :auto_start, true)
      ]
    )
  end

  def options(opts \\ []) do
    opts
    |> NimbleOptions.validate!(options_schema())
    |> Enum.into(%{})
  end

  ## Client Interface

  @doc false
  def start_link(opts) do
    options = options(opts)
    supervisor = start_link()

    if options.auto_start, do: start_fetcher!()

    supervisor
  end

  defp start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Server Callbacks

  @doc false
  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @doc false
  def stop do
    Supervisor.stop(__MODULE__)
  end

  @doc """
  Get the status of the Forex exchange rate fetcher process.
  If the process is running, it returns `:running`,
  if it has been initiated but not running, it returns `:stopped`,
  otherwise, it returns `:not_started`.
  """
  def fetcher_status do
    cond do
      fetcher_running?() -> :running
      fetcher_initiated?() -> :stopped
      true -> :not_started
    end
  end

  @doc """
  Check if the Forex exchange rate fetcher process is running.
  """
  def fetcher_running?, do: !!Process.whereis(Fetcher)

  @doc """
  Check if the Forex exchange rate fetcher process has been initiated.
  """
  def fetcher_initiated? do
    Supervisor.which_children(__MODULE__)
    |> Enum.any?(fn
      {Fetcher, _pid, _type, _args} -> true
      _ -> false
    end)
  end

  @doc """
  Start the Forex exchange rate fetcher process.
  """
  def start_fetcher(opts \\ Fetcher.options()) do
    Supervisor.start_child(__MODULE__, fetcher_spec(opts))
  end

  @doc """
  Stop the Forex exchange rate fetcher process.
  """
  def stop_fetcher do
    Supervisor.terminate_child(__MODULE__, Fetcher)
  end

  @doc """
  Restart the stoped Forex exchange rate fetcher process.
  """
  def restart_fetcher do
    Supervisor.restart_child(__MODULE__, Fetcher)
  end

  @doc """
  Delete the Forex exchange rate fetcher process from the supervisor.
  """
  def delete_fetcher do
    Supervisor.delete_child(__MODULE__, Fetcher)
  end

  ## Internal Functions

  defp start_fetcher! do
    case Fetcher.start() do
      {:ok, _pid} -> :ok
      {:error, reason} -> raise "Error starting exchange rate fetcher fetcher: #{inspect(reason)}"
    end
  end

  defp fetcher_spec(opts) do
    %{
      id: Fetcher,
      start: {Fetcher, :start_link, [opts]}
    }
  end
end
