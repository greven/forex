defmodule Forex.Cache do
  @moduledoc """
  A simpe caching layer to cache the responses from the `Forex.Feed` module.

  Since the ECB reference rates are usually updated at around 16:00 CET
  every working day we can cache the response.

  The cache is stored in the ETS table and is automatically invalidated after
  the time-to-live (TTL) expires.
  """

  use GenServer
  import Record

  @table :forex_cache
  @ttl :timer.hours(12)

  @ets_options [
    :set,
    :public,
    :named_table,
    read_concurrency: true
  ]

  # Cache Entry
  defrecord(:entry, key: nil, value: nil, touched: nil, ttl: nil)

  ## Client Interface

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  List all entries in the ETS cache.
  """
  def list, do: list_entries()

  @doc """
  Get the cache entry with the given `key`
  """
  def get(key), do: get_entry(key)

  @doc """
  Runs a resolver function if the `key` in the `table` is not already cached.
  ## Examples
      with {:ok, rates} <- Forex.Cache.resolve(:current, fn ->  Forex.Feed.current_rates() end) do
        # Do something with rates
      end
  """
  def resolve(key, resolver, opts \\ []) when is_function(resolver, 0) do
    resolve_entry(key, resolver, opts)
  end

  @doc """
  Insert a new entry into the cache with the given `key` and `value`.
  """
  def insert(key, value, opts \\ []), do: insert_entry(key, value, opts)

  @doc """
  Updates a cache entry from with the given `key` and `value`.
  """
  def update(key, changes), do: update_entry(key, changes)

  @doc """
  Delete an entry from the cache with the given `key`.
  """
  def delete(key), do: delete_entry(key)

  @doc """
  Clears all values in the cache table.
  """
  def clear, do: clear_ets_table()

  ## Server Callbacks

  def init(state) do
    :ets.new(@table, @ets_options)
    {:ok, state}
  rescue
    ArgumentError -> {:stop, :already_started}
  end

  defp list_entries do
    list_values = fn list ->
      list
      |> Keyword.values()
      |> Enum.map(&{elem(&1, 1), elem(&1, 2)})
      |> Enum.into(%{})
    end

    case :ets.tab2list(@table) do
      [_ | _] = list -> list_values.(list)
      _ -> nil
    end
  end

  defp get_entry(key) do
    case :ets.lookup(@table, key) do
      [] ->
        :not_found

      [{^key, {:entry, ^key, value, touched, ttl}}] ->
        case expired?(touched, ttl) do
          false ->
            value

          true ->
            :ets.delete(@table, key)
            :not_found
        end
    end
  end

  defp resolve_entry(key, resolver, opts) do
    case get_entry(key) do
      :not_found ->
        with {:ok, result} <- resolver.() do
          insert_entry(key, result, opts)
          result
        end

      result ->
        result
    end
  end

  defp insert_entry(key, value, opts) do
    ttl = Keyword.get(opts, :ttl, @ttl)
    :ets.insert(@table, {key, entry(key: key, value: value, touched: now(), ttl: ttl)})
  end

  defp update_entry(key, changes) do
    {:ok, :ets.update_element(@table, key, changes)}
  end

  defp delete_entry(key) do
    :ets.delete(@table, key)
  end

  defp clear_ets_table do
    :ets.delete(@table)
    :ets.new(@table, @ets_options)
  end

  defp expired?(touched, ttl), do: now() - touched >= ttl

  # Return current timestamp in milliseconds
  defp now, do: System.system_time(:millisecond)
end
