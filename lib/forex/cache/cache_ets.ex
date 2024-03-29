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
  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value, _}] -> value
      [] -> nil
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
  def delete(key) do
    :ets.delete(@table, key)
  end

  @impl true
  def reset do
    :ets.delete(@table)
    :ets.new(@table, @ets_options)
  end

  @impl true
  def current_rates do
    case get(:current_rates) do
      nil -> {:error, Forex.FeedError, "No exchange rates were found"}
      rates -> {:ok, rates}
    end
  end

  @impl true
  def last_ninety_days_rates do
    case get(:last_ninety_days_rates) do
      nil -> {:error, Forex.FeedError, "No exchange rates were found"}
      rates -> {:ok, rates}
    end
  end

  @impl true
  def historic_rates do
    case get(:historic_rates) do
      nil -> {:error, Forex.FeedError, "No exchange rates were found"}
      rates -> {:ok, rates}
    end
  end
end
