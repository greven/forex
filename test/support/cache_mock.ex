defmodule Forex.CacheMock do
  @moduledoc """
  InMemory implementation of the Forex.Cache behaviour using process dictionary.
  Provides isolation for concurrent tests without ETS table conflicts.
  """

  @behaviour Forex.Cache

  @impl true
  def init do
    Process.put({__MODULE__, :cache}, %{})
    Process.put({__MODULE__, :last_updated}, %{})
    :ok
  end

  @impl true
  def get(key, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, :infinity)
    cache = Process.get({__MODULE__, :cache}, %{})
    last_updated = Process.get({__MODULE__, :last_updated}, %{})

    case Map.get(cache, key) do
      nil ->
        nil

      value ->
        updated_at = Map.get(last_updated, key)

        case expired?(updated_at, ttl) do
          true ->
            delete(key)
            nil

          false ->
            value
        end
    end
  end

  @impl true
  def put(key, value, %DateTime{} = updated_at) do
    cache = Process.get({__MODULE__, :cache}, %{})
    last_updated = Process.get({__MODULE__, :last_updated}, %{})

    Process.put({__MODULE__, :cache}, Map.put(cache, key, value))
    Process.put({__MODULE__, :last_updated}, Map.put(last_updated, key, updated_at))

    value
  end

  @impl true
  def delete(key) do
    cache = Process.get({__MODULE__, :cache}, %{})
    last_updated = Process.get({__MODULE__, :last_updated}, %{})

    Process.put({__MODULE__, :cache}, Map.delete(cache, key))
    Process.put({__MODULE__, :last_updated}, Map.delete(last_updated, key))

    :ok
  end

  @impl true
  def last_updated do
    Process.get({__MODULE__, :last_updated}, %{})
    |> Enum.to_list()
  end

  @impl true
  def last_updated(key) do
    last_updated = Process.get({__MODULE__, :last_updated}, %{})
    Map.get(last_updated, key)
  end

  @impl true
  def reset do
    Process.put({__MODULE__, :cache}, %{})
    Process.put({__MODULE__, :last_updated}, %{})
    :ok
  end

  @impl true
  def resolve(key, resolver, opts \\ []) do
    use_cache = Keyword.get(opts, :use_cache, true)

    if use_cache do
      case get(key, opts) do
        nil ->
          resolve_and_store(resolver, key)

        value ->
          {:ok, value}
      end
    else
      resolver.()
    end
  end

  defp resolve_and_store(resolver, key) do
    case resolver.() do
      {:ok, value} ->
        put(key, value, DateTime.utc_now())
        {:ok, value}

      error ->
        error
    end
  end

  @impl true
  def initialized? do
    true
  end

  @impl true
  def terminate do
    reset()
    :ok
  end

  # Private helper functions
  defp expired?(_updated_at, :infinity), do: false
  defp expired?(_updated_at, nil), do: false
  defp expired?(nil, _ttl), do: true

  defp expired?(updated_at, ttl) do
    expiry_time = DateTime.add(updated_at, ttl, :millisecond)
    DateTime.compare(DateTime.utc_now(), expiry_time) == :gt
  end
end
