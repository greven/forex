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
  @callback get(key :: any()) :: term() | nil

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
  Delete an entry from the cache with the given `key`.
  """
  @callback delete(key :: any()) :: term()

  @doc """
  Reset the cache table.
  """
  @callback reset() :: any()

  @doc """
  Resolve the cache entry with the `key` `:current_rates`.
  """
  @callback current_rates() :: {:ok, list(map())} | {:error, {Exception.t(), String.t()}}

  @doc """
  Resolve the cache entry with the `key` `:last_ninety_days_rates`.
  """
  @callback last_ninety_days_rates() :: {:ok, list(map())} | {:error, {Exception.t(), String.t()}}

  @doc """
  Resolve the cache entry with the `key` `:historic_rates`.
  """
  @callback historic_rates() :: {:ok, list(map())} | {:error, {Exception.t(), String.t()}}

  def cache_module, do: Forex.Fetcher.options().cache_module

  def current_rates do
    cache_module().current_rates()
  end

  def last_ninety_days_rates do
    cache_module().last_ninety_days_rates()
  end

  def historic_rates do
    cache_module().historic_rates()
  end
end
