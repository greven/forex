defmodule Forex.Cache.DETS do
  @moduledoc """
  Implementation of the `Forex.Cache` behaviour using DETS.
  """

  @behaviour Forex.Cache

  @table :forex_cache

  @impl true
  def init do
    path = dets_file_path()
    path |> to_string() |> Path.dirname() |> File.mkdir_p!()

    case :dets.open_file(@table, file: path) do
      {:ok, table_name} ->
        table_name

      {:error, reason} ->
        raise "Could not open DETS cache file #{inspect(to_string(path))}: #{inspect(reason)}"
    end
  end

  @impl true
  def get(key, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, :infinity)

    case :dets.lookup(@table, key) do
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
    :dets.insert(@table, {key, value, updated_at})
    value
  end

  @impl true
  def last_updated do
    @table
    |> :dets.match({:"$1", :_, :"$2"})
    |> Enum.map(fn [key, updated_at] -> {key, updated_at} end)
  end

  @impl true
  def last_updated(key) do
    case :dets.lookup(@table, key) do
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
    :dets.delete(@table, key)
  end

  @impl true
  def terminate do
    :dets.close(@table)
  end

  @impl true
  def reset do
    case :dets.info(@table) do
      :undefined ->
        :noop

      table_info ->
        filepath = Keyword.get(table_info, :filename)

        :dets.close(@table)
        File.rm(to_string(filepath))
        init()

        :ok
    end
  end

  @impl true
  def initialized? do
    :dets.info(@table) != :undefined
  end

  @doc """
  Returns `true` if all given `keys` have non-expired entries in the cache
  for the given `ttl` (in milliseconds).

  This can be used to determine whether a startup fetch should be skipped
  because the persisted cache is still fresh.
  """
  @spec warm?(keys :: [any()], ttl :: non_neg_integer()) :: boolean()
  def warm?(keys, ttl) when is_list(keys) and is_integer(ttl) do
    initialized?() and Enum.all?(keys, fn key -> get(key, ttl: ttl) != nil end)
  end

  defp expired?(touched, ttl) do
    DateTime.diff(DateTime.utc_now(), touched, :millisecond) > ttl
  end

  defp default_file_path do
    :code.priv_dir(:forex)
    |> Path.join(".forex_cache")
    |> String.to_charlist()
  end

  defp dets_file_path do
    Application.get_env(:forex, :dets_file_path, default_file_path())
  end
end
