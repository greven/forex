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

  To configure the `Forex.Fetcher` module, the following options are available:

  * `use_cache` - A boolean value that determines if the cache should be used.
    The default value is `true`.

  * `cache_module` - The cache module to use. The default value is `Forex.Cache.ETS`.

  * `schedular_interval` - The interval in milliseconds to fetch the exchange rates
    from the feed. The default value is `12 hours`.
  """

  use GenServer

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
      schedular_interval: [
        type: :integer,
        default: Application.get_env(:forex, :schedular_interval, @default_schedular_interval)
      ]
    )
  end

  @doc """
  Validate and return the options for the `Forex.Fetcher` module functions,
  using default values if the options are not provided.
  """

  def options(opts \\ []) do
    opts
    |> NimbleOptions.validate!(options_schema())
    |> Enum.into(%{})
  end

  ## Client Interface

  @doc false
  def start_link(opts \\ Fetcher.options()) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def start(opts \\ Fetcher.options()) do
    Forex.Fetcher.Supervisor.start_fetcher(opts)
  end

  @doc """
  Fetch the respective exchange rates from the cache or the feed,
  based on the `key` and the `opts`.

  The `key` can be one of the following atoms:

  * `:latest_rates` - Fetch the latest exchange rates.
  * `:last_ninety_days_rates` - Fetch the exchange rates for the last 90 days.
  * `:historic_rates` - Fetch the exchange rates for a specific date.

  The `opts` can be a keyword list with the module options, that is,
  the options returned from the `Forex.Fetcher.options/1` function.
  """
  def get(key, opts \\ [])

  def get(:latest_rates, opts) do
    feed_fn = Keyword.get(opts, :feed_fn) || {Feed, :latest_rates, []}
    fetch_rates(:latest_rates, feed_fn, opts)
  end

  def get(:last_ninety_days_rates, opts) do
    feed_fn = Keyword.get(opts, :feed_fn) || {Feed, :last_ninety_days_rates, []}
    fetch_rates(:last_ninety_days_rates, feed_fn, opts)
  end

  def get(:historic_rates, opts) do
    feed_fn = Keyword.get(opts, :feed_fn) || {Feed, :historic_rates, []}
    fetch_rates(:historic_rates, feed_fn, opts)
  end

  ## Server Callbacks

  @doc false
  def init(opts) do
    if opts.use_cache, do: opts.cache_module.init()
    schedule_work(:latest_rates, 0)
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
  def handle_info(:latest_rates, opts) do
    fetch_opts = Keyword.new(opts)

    fetch_rates(:latest_rates, {Feed, :latest_rates, []}, fetch_opts)
    schedule_work(:latest_rates, opts.schedular_interval)

    {:noreply, opts}
  end

  @doc false
  def handle_info(:last_ninety_days_rates, opts) do
    fetch_opts = Keyword.new(opts)

    fetch_rates(
      :last_ninety_days_rates,
      {Feed, :last_ninety_days_rates, []},
      fetch_opts
    )

    schedule_work(:last_ninety_days_rates, opts.schedular_interval)

    {:noreply, opts}
  end

  ## Private Functions

  defp fetch_rates(cache_key, feed_fn, opts) do
    feed_fn = resolve_feed_fn(feed_fn)

    use_cache = Cache.initialized?() and Keyword.get(opts, :use_cache, true)
    schedular_interval = Keyword.get(opts, :schedular_interval, @default_schedular_interval)

    if use_cache,
      do: Cache.resolve(cache_key, feed_fn, ttl: schedular_interval),
      else: feed_fn.()
  end

  defp resolve_feed_fn({feed_mod, feed_fn, feed_args})
       when is_atom(feed_mod) and is_atom(feed_fn) and is_list(feed_args) do
    fn -> apply(feed_mod, feed_fn, feed_args) end
  end

  defp resolve_feed_fn(feed_fn) when is_function(feed_fn), do: feed_fn

  defp schedule_work(:latest_rates, interval_ms) when is_integer(interval_ms) do
    Process.send_after(self(), :latest_rates, interval_ms)
  end

  defp schedule_work(:last_ninety_days_rates, interval_ms) when is_integer(interval_ms) do
    Process.send_after(self(), :last_ninety_days_rates, interval_ms)
  end
end
