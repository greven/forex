defmodule Forex.Feed do
  @moduledoc """
  This module is responsible for fetching the latest exchange rates from the
  European Central Bank (ECB) and parsing the XML response.
  """

  import SweetXml

  def base_url, do: "https://www.ecb.europa.eu/stats/eurofxref"

  def path(:current_rates), do: "/eurofxref-daily.xml"
  def path(:last_ninety_days_rates), do: "/eurofxref-hist-90d.xml"
  def path(:historic_rates), do: "/eurofxref-hist.xml"

  # --------------------------------
  # Feed API
  # --------------------------------

  @spec current_rates(options :: keyword()) :: {:ok, list(map())} | {:error, term()}
  def current_rates(options \\ []) do
    fetch(:current_rates, options)
    |> case do
      {:ok, %{body: body}} ->
        {:ok, parse_rate(body)}

      {:error, reason} ->
        {Forex.FeedError, reason}
    end
  end

  @spec last_ninety_days_rates(options :: keyword()) :: {:ok, list(map())} | {:error, term()}
  def last_ninety_days_rates(options \\ []) do
    fetch(:last_ninety_days_rates, options)
    |> case do
      {:ok, %{body: body}} ->
        {:ok, parse_multiple_rates(body)}

      {:error, reason} ->
        {Forex.FeedError, reason}
    end
  end

  @spec historic_rates(options :: keyword()) :: {:ok, list(map())} | {:error, term()}
  def historic_rates(options \\ []) do
    fetch(:historic_rates, options)
    |> case do
      {:ok, %{body: body}} ->
        {:ok, parse_multiple_rates(body)}

      {:error, reason} ->
        {Forex.FeedError, reason}
    end
  end

  # Parse the XML of a single daily rates
  defp parse_rate(body) do
    body
    |> SweetXml.parse()
    |> SweetXml.xpath(~x"//gesmes:Envelope//Cube//Cube//Cube"l,
      currency: ~x"./@currency"s,
      rate: ~x"./@rate"s
    )
  end

  # Parse the XML of a list of daily rates
  defp parse_multiple_rates(body) do
    body
    |> SweetXml.parse()
    |> SweetXml.xpath(~x"//gesmes:Envelope/Cube/Cube"l,
      time: ~x"./@time"s,
      rates: [
        ~x"./Cube"l,
        currency: ~x"./@currency"s,
        rate: ~x"./@rate"s
      ]
    )
  end

  # --------------------------------
  # Fetch API
  # --------------------------------

  def fetch(feed, options \\ []) do
    options = Keyword.merge([url: path(feed)], options)

    base_request()
    |> Req.get(options)
  end

  def fetch!(feed, options \\ []) do
    options = Keyword.merge([url: path(feed)], options)

    base_request()
    |> Req.get!(options)
  end

  defp base_request,
    do: Req.new(base_url: base_url())
end
