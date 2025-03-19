defmodule Forex.Cache.ETS do
  @moduledoc """
  Implementation of the `Forex.Cache` behaviour using ETS.
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
  def last_updated do
    :ets.tab2list(@table)
    |> Enum.map(fn {key, _value, updated_at} -> {key, updated_at} end)
  end

  @impl true
  def last_updated(key) do
    case :ets.lookup(@table, key) do
      [{^key, _value, updated_at}] -> updated_at
      [] -> nil
    end
  end

  @impl true
  def resolve(key, resolver, opts \\ []) do
    resolver_fn =
      case resolver do
        {resolver_mod, resolver_fn, resolver_args} ->
          fn -> apply(resolver_mod, resolver_fn, resolver_args) end

        resolver when is_function(resolver) ->
          resolver
      end

    case get(key, opts) do
      nil ->
        case resolver_fn.() do
          {:ok, value} ->
            put(key, value, DateTime.utc_now())
            {:ok, value}

          _ ->
            {:error, :cache_resolver_failed}
        end

      value ->
        {:ok, value}
    end
  end

  @impl true
  def delete(key) do
    :ets.delete(@table, key)
  end

  @impl true
  def terminate do
    :ets.delete(@table)
  end

  @impl true
  def reset do
    if :ets.info(@table) != :undefined do
      :ets.delete(@table)
      :ets.new(@table, @ets_options)

      :ok
    else
      :noop
    end
  end

  @impl true
  def initialized? do
    :ets.info(@table) != :undefined
  end

  defp expired?(touched, ttl) do
    DateTime.diff(DateTime.utc_now(), touched, :millisecond) > ttl
  end
end
