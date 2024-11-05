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
  option in the `Forex` application environment, example, to fetch the rates
  every 24 hours:

    ```elixir
    config :forex, schedular_interval: 24 * 60 * 60 * 1000
    ```
  """

  use GenServer
  require Logger

  alias __MODULE__

  alias Forex.Cache
  alias Forex.Feed

  ##  Options

  @default_cache_module Forex.Cache.ETS
  @default_schedular_interval :timer.hours(12)

  defp options_schema do
    NimbleOptions.new!(
      use_cache: [
        type: :boolean,
        default: Application.get_env(:forex, :use_cache, true)
      ],
      cache_module: [
        type: :atom,
        default: Application.get_env(:forex, :cache_module, @default_cache_module)
      ],
      auto_start: [
        type: :boolean,
        default: Application.get_env(:forex, :auto_start, true)
      ],
      schedular_interval: [
        type: :integer,
        default: Application.get_env(:forex, :schedular_interval, @default_schedular_interval)
      ]
    )
  end

  def options(opts \\ []) do
    opts
    |> NimbleOptions.validate!(options_schema())
    |> Enum.into(%{})
  end

  ## Client Interface

  def start_link(opts \\ Fetcher.options()) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start(opts \\ Fetcher.options()) do
    Fetcher.Supervisor.start_fetcher(opts)
  end

  def current_rates(use_cache \\ true) do
    GenServer.call(__MODULE__, {:current_rates, use_cache})
  end

  def last_ninety_days_rates(use_cache \\ true) do
    GenServer.call(__MODULE__, {:last_ninety_days_rates, use_cache})
  end

  def historic_rates(use_cache \\ true) do
    GenServer.call(__MODULE__, {:historic_rates, use_cache})
  end

  ## Server Callbacks

  @doc false
  def init(opts) do
    if opts.use_cache, do: opts.cache_module.init()
    schedule_work(:current_rates, 0)
    schedule_work(:last_ninety_days_rates, 0)

    {:ok, opts}
  end

  @doc false
  def terminate(:normal, opts) do
    opts.cache_module.terminate()
  end

  @doc false
  def terminate(:shutdown, opts) do
    opts.cache_module.terminate()
  end

  @doc false
  def terminate(reason, _config) do
    Logger.error("[Forex.Fetcher] Terminate with #{inspect(reason)}")
  end

  @doc false
  def handle_call({:current_rates, use_cache}, _from, opts) do
    opts = Map.merge(opts, %{use_cache: use_cache})

    {:reply, fetch_rates(:current_rates, &Feed.current_rates/0, opts), opts}
  end

  @doc false
  def handle_call({:last_ninety_days_rates, use_cache}, _from, opts) do
    opts = Map.merge(opts, %{use_cache: use_cache})

    {:reply, fetch_rates(:last_ninety_days_rates, &Feed.last_ninety_days_rates/0, opts), opts}
  end

  @doc false
  def handle_call({:historic_rates, use_cache}, _from, opts) do
    opts = Map.merge(opts, %{use_cache: use_cache})

    {:reply, fetch_rates(:historic_rates, &Feed.historic_rates/0, opts), opts}
  end

  @doc false
  def handle_info(:current_rates, opts) do
    fetch_rates(:current_rates, &Feed.current_rates/0, opts)
    schedule_work(:current_rates, opts.schedular_interval)
    {:noreply, opts}
  end

  @doc false
  def handle_info(:last_ninety_days_rates, opts) do
    fetch_rates(:last_ninety_days_rates, &Feed.last_ninety_days_rates/0, opts)
    schedule_work(:last_ninety_days_rates, opts.schedular_interval)
    {:noreply, opts}
  end

  defp fetch_rates(cache_key, feed_function, opts) when is_function(feed_function, 0) do
    if opts.use_cache,
      do: Cache.resolve(cache_key, feed_function, ttl: opts.schedular_interval),
      else: feed_function.()
  end

  defp schedule_work(:current_rates, interval_ms) when is_integer(interval_ms) do
    Process.send_after(self(), :current_rates, interval_ms)
  end

  defp schedule_work(:last_ninety_days_rates, interval_ms) when is_integer(interval_ms) do
    Process.send_after(self(), :last_ninety_days_rates, interval_ms)
  end

  defp schedule_work(_, _), do: :ok
end
