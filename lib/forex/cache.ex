defmodule Forex.Cache do
  @moduledoc """
  Since the ECB reference rates are usually updated at around 16:00 CET
  every working day we should cache the response.

  This module defines a simple caching layer behaviour to cache the
  responses from the `Forex.Feed` module.

  The default implementation uses ETS as the cache storage.
  You can override the cache module by setting the `:cache_module` configuration option:

  ```elixir
  config :forex, cache_module: MyApp.ForexCache
  ```
  """

  @cache_mod Application.compile_env(:forex, :cache_module, Forex.Cache.ETS)

  @doc """
  Inits the cache.
  """
  @callback init() :: any()

  @doc """
  Get the cache entry with the given `key`.
  Returns `nil` if the entry does not exist.
  """
  @callback get(key :: any(), opts :: Keyword.t()) :: term()

  @doc """
  Put a new entry into the cache with the given `key` and `value`.
  """
  @callback put(key :: any(), value :: term(), DateTime.t()) :: term()

  @doc """
  Get a list of all keys in the cache and the respective
  updated at timestamps.
  """
  @callback last_updated() :: [{any(), DateTime.t()}] | nil

  @doc """
  Get the latest updated at timestamp for the given `key`.
  Returns `nil` if the entry does not exist.
  """
  @callback last_updated(key :: any()) :: DateTime.t() | nil

  @doc """
  Resolve the cache entry with the given `key` using the given `resolver`.
  If the entry does not exist, the `resolver` function, an mfa tuple, is called and the
  result is stored in the cache.

  Example:

    Forex.Cache.resolve(:latest_rates, {Forex.Feed, :fetch_latest_rates, []})
  """
  @callback resolve(key :: any(), resolver :: mfa() | function(), opts :: Keyword.t()) :: term()

  @doc """
  Delete an entry from the cache with the given `key`.
  """
  @callback delete(key :: any()) :: term()

  @doc """
  Reset the cache table.
  """
  @callback reset() :: any()

  @doc """
  Terminate the cache process.
  """
  @callback terminate() :: any()

  @doc """
  Check if the cache is initialized.
  """
  @callback initialized?() :: boolean()

  def cache_mod, do: @cache_mod

  def latest_rates,
    do: cache_mod().get(:latest_rates)

  def last_ninety_days_rates,
    do: cache_mod().get(:last_ninety_days_rates)

  def historic_rates,
    do: cache_mod().get(:historic_rates)

  def resolve(key, resolver, opts \\ []) do
    cache_mod().resolve(key, resolver, opts)
  end

  def delete(key) do
    cache_mod().delete(key)
  end

  def last_updated(key) do
    cache_mod().last_updated(key)
  end

  def last_updated do
    cache_mod().last_updated()
  end

  def init do
    cache_mod().init()
  end

  def terminate do
    cache_mod().terminate()
  end

  def reset do
    cache_mod().reset()
  end

  def initialized? do
    cache_mod().initialized?()
  end
end
