defmodule Forex.Cache do
  @moduledoc """
  Since the ECB reference rates are usually updated at around 16:00 CET
  every working day we should cache the response.

  This module defines a simple caching layer behaviour to cache the
  responses from the `Forex.Feed` module.
  """

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
  Get the latest updated at timestamp for the given `key`.
  Returns `nil` if the entry does not exist.
  """
  @callback last_updated(key :: any()) :: DateTime.t() | nil

  @doc """
  Resolve the cache entry with the given `key` using the given `resolver`.
  If the entry does not exist, the `resolver` function is called and the
  result is stored in the cache.
  """
  @callback resolve(key :: any(), resolver :: function(), opts :: Keyword.t()) :: term()

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

  def cache_module,
    do: Forex.Fetcher.options()[:cache_module]

  def current_rates,
    do: cache_module().get(:current_rates)

  def last_ninety_days_rates,
    do: cache_module().get(:last_ninety_days_rates)

  def historic_rates,
    do: cache_module().get(:historic_rates)

  def resolve(key, resolver, opts \\ []) do
    cache_module().resolve(key, resolver, opts)
  end
end
