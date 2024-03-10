defmodule Forex.Feed do
  @moduledoc """
  This module is responsible for fetching the latest exchange rates from the
  European Central Bank (ECB) and parsing the XML response.
  """

  import SweetXml

  @base_url "https://www.ecb.europa.eu/stats/eurofxref"

  def current_rates do
    base_request()
    |> Req.get(url: "/eurofxref-daily.xml")
    |> case do
      {:ok, %{body: body}} ->
        body
        |> SweetXml.parse()
        |> SweetXml.xpath(~x"//gesmes:Envelope//Cube//Cube//Cube"l,
          currency: ~x"@currency"s,
          rate: ~x"@rate"s
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  def last_ninety_days_rates do
    base_request()
    |> Req.get(url: "/eurofxref-hist-90d.xml")
    |> case do
      {:ok, %{body: body}} ->
        body
        |> SweetXml.parse()
        |> SweetXml.xpath(~x"//gesmes:Envelope//Cube//Cube"l,
          time: ~x"@time"s,
          rates: [
            ~x"Cube"l,
            currency: ~x"@currency"s,
            rate: ~x"@rate"s
          ]
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  def historical_rates do
    base_request()
    |> Req.get(url: "/eurofxref-hist.xml")
    |> case do
      {:ok, %{body: body}} ->
        body
        |> SweetXml.parse()
        |> SweetXml.xpath(~x"//gesmes:Envelope//Cube//Cube"l,
          time: ~x"@time"s,
          rates: [
            ~x"Cube"l,
            currency: ~x"@currency"s,
            rate: ~x"@rate"s
          ]
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  def currencies do
    current_rates()
    |> Enum.map(&Map.get(&1, :currency))
  end

  defp base_request do
    Req.new(base_url: @base_url)
  end
end
