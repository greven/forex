defmodule Forex.Fetcher.Supervisor do
  @moduledoc """
  Supervisor for the Forex.Fetcher module that fetches exchange rates.

  The Supervisor provides functionality to start, stop and restarting the `Forex.Fetcher`.

  The `Forex.Fetcher.Supervisor` accepts the following options:

  * `auto_start` - A boolean value that determines if the fetcher process should be started
    automatically when the supervisor is started. The default value is `true`.

  * `use_cache` - A boolean value that determines if the cache should be used.
    The default value is `true`.
  """

  use Supervisor

  alias Forex.Fetcher
  alias Forex.Options

  ## Client Interface

  @doc """
  Starts the `Forex.Fetcher.Supervisor` process.

  This function should be called in your application supervision tree to start
  the Forex exchange rate fetcher.

  ## Options

  * `auto_start` - A boolean value that determines if the fetcher process should be started
    automatically when the supervisor is started. The default value is `true`.

  * `use_cache` - A boolean value that determines if the cache should be used.
    The default value is `true`.

  * `name` - The name to register the supervisor process under. Defaults to
    `Forex.Fetcher.Supervisor`.
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    options = Options.fetcher_supervisor_options(opts)
    supervisor = start_supervisor(name)

    if options[:auto_start], do: start_fetcher!(name)

    supervisor
  end

  defp start_supervisor(name) do
    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  ## Server Callbacks

  @doc false
  def init(:ok) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @doc false
  def stop(supervisor \\ __MODULE__) do
    Supervisor.stop(supervisor)
  end

  @doc """
  Get the status of the Forex exchange rate fetcher process.
  If the process is running, it returns `:running`,
  if it has been initiated but not running, it returns `:stopped`,
  otherwise, it returns `:not_started`.
  """
  def fetcher_status(supervisor \\ __MODULE__) do
    cond do
      fetcher_running?(supervisor) -> :running
      fetcher_initiated?(supervisor) -> :stopped
      true -> :not_started
    end
  end

  @doc """
  Check if the Forex exchange rate fetcher process is running.
  """
  def fetcher_running?(supervisor \\ __MODULE__) do
    case Supervisor.which_children(supervisor) do
      [] ->
        false

      children ->
        Enum.any?(children, fn
          {Fetcher, pid, _type, _args} when is_pid(pid) -> Process.alive?(pid)
          _ -> false
        end)
    end
  end

  @doc """
  Check if the Forex exchange rate fetcher process has been initiated.
  """
  def fetcher_initiated?(supervisor \\ __MODULE__) do
    Supervisor.which_children(supervisor)
    |> Enum.any?(fn
      {Fetcher, _pid, _type, _args} -> true
      _ -> false
    end)
  end

  @doc """
  Start the Forex exchange rate fetcher process.
  """
  def start_fetcher(opts_or_supervisor \\ __MODULE__)

  def start_fetcher(supervisor) when is_atom(supervisor) or is_pid(supervisor) do
    start_fetcher(supervisor, Options.fetcher_options())
  end

  def start_fetcher(opts) when is_list(opts) do
    start_fetcher(__MODULE__, opts)
  end

  def start_fetcher(supervisor, opts) do
    {name, rest} = Keyword.pop(opts, :name)
    fetcher_opts = Options.fetcher_options(rest)
    opts = if name, do: Keyword.put(fetcher_opts, :name, name), else: fetcher_opts

    Supervisor.start_child(supervisor, fetcher_spec(opts))
  end

  @doc """
  Stop the Forex exchange rate fetcher process.
  """
  def stop_fetcher(supervisor \\ __MODULE__) do
    Supervisor.terminate_child(supervisor, Fetcher)
  end

  @doc """
  Restart the stoped Forex exchange rate fetcher process.
  """
  def restart_fetcher(supervisor \\ __MODULE__) do
    Supervisor.restart_child(supervisor, Fetcher)
  end

  @doc """
  Delete the Forex exchange rate fetcher process from the supervisor.
  """
  def delete_fetcher(supervisor \\ __MODULE__) do
    Supervisor.delete_child(supervisor, Fetcher)
  end

  ## Private Functions

  defp start_fetcher!(supervisor) do
    case start_fetcher(supervisor) do
      {:ok, _pid} -> :ok
      {:error, reason} -> raise "Error starting exchange rate fetcher: #{inspect(reason)}"
    end
  end

  defp fetcher_spec(opts) do
    %{
      id: Fetcher,
      start: {Forex.Fetcher, :start_link, [opts]}
    }
  end
end
