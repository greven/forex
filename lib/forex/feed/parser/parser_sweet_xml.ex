defmodule Forex.Feed.Parser.ParserSweetXml do
  @moduledoc """
  This module implements the Forex.Parser behaviour using the SweetXml library.
  """

  import SweetXml

  @behaviour Forex.Feed.Parser

  @doc false
  @impl true
  def parse_rates(body) do
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
end
