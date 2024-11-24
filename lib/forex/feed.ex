defmodule Forex.Feed do
  @moduledoc """
  This module is responsible for fetching the latest exchange rates from the
  European Central Bank (ECB) and parsing the XML response.
  """

  alias Forex.Feed.Parser

  def base_url, do: "https://www.ecb.europa.eu/stats/eurofxref"

  def path(:current_rates), do: "/eurofxref-daily.xml"
  def path(:last_ninety_days_rates), do: "/eurofxref-hist-90d.xml"
  def path(:historic_rates), do: "/eurofxref-hist.xml"

  def api_mod do
    Application.get_env(:forex, :feed_api, __MODULE__.API.HTTP)
  end

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
