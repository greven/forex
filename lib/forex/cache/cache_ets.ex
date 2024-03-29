defmodule Forex.Cache.ETS do
  @moduledoc """
  Implementation of the Forex.Cache behaviour using ETS.
  """

  @behaviour Forex.Cache

  @table :forex_cache

  @ets_options [
    :set,
    :public,
    :named_table,
    read_concurrency: true
  ]

  @impl true
  def init do
    if :ets.info(@table) == :undefined,
      do: :ets.new(@table, @ets_options),
      else: @table
  end

  @impl true
  def get(key, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, :infinity)

    case :ets.lookup(@table, key) do
      [{^key, value, updated_at}] ->
        case expired?(updated_at, ttl) do
          false ->
            value

          true ->
            delete(key)
            nil
        end

      [] ->
        nil
    end
  end

  @impl true
  def put(key, value, %DateTime{} = updated_at) do
    :ets.insert(@table, {key, value, updated_at})
    value
  end

  @impl true
  def last_updated(key) do
    case :ets.lookup(@table, key) do
      [{^key, _value, updated_at}] -> updated_at
      [] -> nil
    end
  end

  @impl true
  def resolve(key, resolver, opts \\ []) when is_function(resolver, 0) do
    case get(key, opts) do
      nil ->
        with {:ok, value} <- resolver.() do
          put(key, value, DateTime.utc_now())
          value
        end

      value ->
        value
    end
  end

  @impl true
  def delete(key) do
    :ets.delete(@table, key)
  end

  @impl true
  def reset do
    :ets.delete(@table)
    :ets.new(@table, @ets_options)
  end

  @impl true
  def terminate do
    :ets.delete(@table)
  end

  defp expired?(touched, ttl) do
    DateTime.diff(DateTime.utc_now(), touched, :millisecond) > ttl
  end
end
