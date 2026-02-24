defmodule Forex.Fetcher do
  @moduledoc """
  The `Forex.Fetcher` module is responsible for fetching the exchange rates
  from the cache or the feed on periodic intervals or on demand.

  The exchange rates are fetched from the cache if the cache is enabled and
  the cache is not stale. Otherwise, the exchange rates are fetched from the
  feed and stored in the cache.

  By default, the exchange rates are fetched from the feed every 12 hours as
  the European Central Bank (ECB) updates the reference rates at around 16:00 CET
  every working day. This can be configured by setting the `:schedular_interval`
  option in the `Forex` application environment or by passing it as an option
  when starting the `Forex.Fetcher` process.
  """

  use GenServer
  require Logger

  alias Forex.Cache
  alias Forex.Options

  @scheduled ~w(latest_rates last_ninety_days_rates)a

  ## Client Interface

  @doc """
  Start the `Forex.Fetcher` process linked to the current process
  with the given options.

  ## Options
  #{NimbleOptions.docs(Options.fetcher_schema())}
  """
  def start_link(opts \\ Options.fetcher_options()) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Start the `Forex.Fetcher` process with the given options.

  ## Options
  #{NimbleOptions.docs(Options.fetcher_schema())}
  """
  def start(opts \\ Options.fetcher_options()) do
    Forex.Fetcher.Supervisor.start_fetcher(opts)
  end

  @doc """
  Fetch the respective exchange rates from the cache or the feed,
  based on the `key` and the `opts`.

  The `key` can be one of the following atoms:

  * `:latest_rates` - Fetch the latest exchange rates.
  * `:last_ninety_days_rates` - Fetch the exchange rates for the last 90 days.
  * `:historic_rates` - Fetch the exchange rates for a specific date.

  ## Options
  #{NimbleOptions.docs(Options.fetcher_schema())}
  """
  def get(key, opts \\ Options.fetcher_options())

  def get(:latest_rates, opts) do
    fetch_rates(:latest_rates, opts)
  end

  def get(:last_ninety_days_rates, opts) do
    fetch_rates(:last_ninety_days_rates, opts)
  end

  def get(:historic_rates, opts) do
    fetch_rates(:historic_rates, opts)
  end

  @doc """
  Returns the default options for the `Forex.Fetcher` process.
  """
  def options, do: Options.fetcher_options()

  @doc """
  Get the options used to start the `Forex.Fetcher` process.
  """
  def get_options(server \\ __MODULE__), do: GenServer.call(server, :options)

  ## Server Callbacks

  @doc false
  def init(opts) do
    if opts[:use_cache], do: Cache.cache_mod().init()

    # Schedule the next refreshes
    schedule_work(:latest_rates, opts[:schedular_interval])
    schedule_work(:last_ninety_days_rates, opts[:schedular_interval])

    {:ok, opts, {:continue, :init_schedule}}
  end

  @doc false
  def handle_continue(:init_schedule, opts) do
    if dets_cache_warm?(@scheduled, opts) do
      Logger.debug("Forex: Exchange rates loaded from cache.")
    else
      tasks = [
        Task.async(fn -> fetch_rates(:latest_rates, opts) end),
        Task.async(fn -> fetch_rates(:last_ninety_days_rates, opts) end)
      ]

      Task.await_many(tasks, 20_000)
      |> Enum.all?(fn result -> match?({:ok, _}, result) end)
      |> case do
        true -> Logger.debug("Forex: Exchange rates updated!")
        false -> Logger.warning("Forex: Some exchange rates failed to update!")
      end
    end

    {:noreply, opts}
  end

  @doc false
  def handle_call(:options, _from, opts) do
    {:reply, opts, opts}
  end

  @doc false
  def handle_info(:latest_rates, opts) do
    fetch_rates(:latest_rates, opts)
    schedule_work(:latest_rates, opts[:schedular_interval])

    {:noreply, opts}
  end

  @doc false
  def handle_info(:last_ninety_days_rates, opts) do
    fetch_rates(:last_ninety_days_rates, opts)
    schedule_work(:last_ninety_days_rates, opts[:schedular_interval])

    {:noreply, opts}
  end

  @doc false
  def terminate(_reason, opts) do
    if opts[:use_cache], do: Cache.cache_mod().terminate()

    :ok
  end

  ## Private Functions

  defp schedule_work(task, interval_ms) when task in @scheduled and is_integer(interval_ms) do
    Process.send_after(self(), task, interval_ms)
  end

  @spec fetch_rates(atom(), [Options.fetcher_option()]) :: {:ok, any()} | {:error, any()}
  defp fetch_rates(key, opts) do
    feed_fn = resolve_feed_fn(key, opts)
    use_cache = Cache.initialized?() and opts[:use_cache]

    if use_cache,
      do: Cache.resolve(key, feed_fn, ttl: opts[:schedular_interval]),
      else: feed_fn.()
  end

  @spec resolve_feed_fn(key :: atom(), opts :: [Options.fetcher_option()]) :: any()
  defp resolve_feed_fn(key, opts) do
    feed_fn = Keyword.get(opts, :feed_fn) || {Forex.Feed, key, []}

    case feed_fn do
      {feed_mod, feed_fn, feed_args}
      when is_atom(feed_mod) and is_atom(feed_fn) and is_list(feed_args) ->
        fn -> apply(feed_mod, feed_fn, feed_args) end

      feed_fn when is_function(feed_fn) ->
        feed_fn

      _ ->
        raise ArgumentError,
              "Invalid feed function option. Expected an MFA tuple or a function."
    end
  end

  # Returns true only when the configured cache module is Forex.Cache.DETS
  # and all scheduled keys have non-expired entries within the current TTL.
  #
  # For any other cache module this always returns false.
  defp dets_cache_warm?(keys, opts) do
    cache_mod = Application.get_env(:forex, :cache_module, Forex.Cache.ETS)

    opts[:use_cache] and
      cache_mod == Cache.DETS and
      Cache.DETS.warm?(keys, opts[:schedular_interval])
  end
end
