defmodule Forex.Feed.Parser.ParserSweetXml do
  @moduledoc """
  This module implements the Forex.Parser behaviour using the SweetXml library.
  """

  import SweetXml

  @behaviour Forex.Feed.Parser

  @path ~x"//gesmes:Envelope/Cube/Cube"l

  @doc false
  @impl true
  def parse_rates(response_body) do
    response_body
    |> SweetXml.parse(dtd: :none)
    |> SweetXml.xpath(@path,
      time: ~x"./@time"s,
      rates: [
        ~x"./Cube"l,
        currency: ~x"./@currency"s,
        rate: ~x"./@rate"s
      ]
    )
  end
end
