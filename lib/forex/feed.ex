defmodule Forex.Feed do
  @moduledoc """
  This module is responsible for fetching the latest exchange rates from the
  European Central Bank (ECB) and parsing the XML response.

  The ECB provides three different feeds:

  - Current exchange rates: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
  - Exchange rates for the last ninety days: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml
  - Historic exchange rates: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.xml

  For each feed, this module provides a function to fetch the rates and parse the response, respectively,
  `current_rates/1`, `last_ninety_days_rates/1`, and `historic_rates/1`.
  """

  alias Forex.Feed.Parser

  @doc """
  The base URL for the European Central Bank (ECB) exchange rate feeds.
  """
  def base_url, do: "https://www.ecb.europa.eu/stats/eurofxref"

  @doc """
  The path for the different exchange rate feeds, corresponding
  to each different feed provided by the European Central Bank (ECB).
  """
  def path(:current_rates), do: "/eurofxref-daily.xml"
  def path(:last_ninety_days_rates), do: "/eurofxref-hist-90d.xml"
  def path(:historic_rates), do: "/eurofxref-hist.xml"

  @doc """
  The API module to use for fetching the exchange rates, by default uses the HTTP API.
  The API module must implement the `Forex.Feed.API` behaviour.

  This is useful for testing purposes, where you can provide a mock API module or
  for using a different API module, for example, an API module that uses a different
  HTTP client.
  """
  def api_mod, do: Application.get_env(:forex, :feed_api, __MODULE__.API.HTTP)

  @doc """
  Fetches the latest exchange rates from the European Central Bank (ECB).
  """
  @spec current_rates(keyword) :: {:ok, map()} | {:error, {module(), term()}}
  def current_rates(options \\ []) do
    case api_mod().get_current_rates(options) do
      {:ok, body} -> {:ok, Parser.parse_rates(body)}
      {:error, reason} -> {:error, {Forex.FeedError, reason}}
    end
  end

  @doc """
  Fetches the exchange rates for the last ninety days from the European Central Bank (ECB).
  """
  @spec last_ninety_days_rates(keyword) :: {:ok, list(map())} | {:error, {module(), term()}}
  def last_ninety_days_rates(options \\ []) do
    case api_mod().get_last_ninety_days_rates(options) do
      {:ok, body} -> {:ok, Parser.parse_rates(body)}
      {:error, reason} -> {:error, {Forex.FeedError, reason}}
    end
  end

  @doc """
  Fetches the historic exchange rates from the European Central Bank (ECB).
  """
  @spec historic_rates(keyword) :: {:ok, list(map())} | {:error, {module(), term()}}
  def historic_rates(options \\ []) do
    case api_mod().get_historic_rates(options) do
      {:ok, body} -> {:ok, Parser.parse_rates(body)}
      {:error, reason} -> {:error, {Forex.FeedError, reason}}
    end
  end
end
