defmodule Forex.Feed do
  @moduledoc """
  This module is responsible for fetching the latest exchange rates from the
  European Central Bank (ECB) and parsing the XML response.
  """

  import SweetXml

  @base_url "https://www.ecb.europa.eu/stats/eurofxref"

  @spec current_rates() :: {:ok, list(map())} | {:error, term()}
  def current_rates do
    base_request()
    |> Req.get(url: "/eurofxref-daily.xml")
    |> case do
      {:ok, %{body: body}} ->
        rates =
          body
          |> SweetXml.parse()
          |> SweetXml.xpath(~x"//gesmes:Envelope//Cube//Cube//Cube"l,
            currency: ~x"@currency"s,
            rate: ~x"@rate"s
          )

        {:ok, rates}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec last_ninety_days_rates() :: {:ok, list(map())} | {:error, term()}
  def last_ninety_days_rates do
    base_request()
    |> Req.get(url: "/eurofxref-hist-90d.xml")
    |> case do
      {:ok, %{body: body}} ->
        rates =
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

        {:ok, rates}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec historic_rates() :: {:ok, list(map())} | {:error, term()}
  def historic_rates do
    base_request()
    |> Req.get(url: "/eurofxref-hist.xml")
    |> case do
      {:ok, %{body: body}} ->
        rates =
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

        {:ok, rates}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp base_request, do: Req.new(base_url: @base_url)
end
