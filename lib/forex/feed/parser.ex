defmodule Forex.Feed.Parser do
  @moduledoc """
  This module defines the behaviour of the parser that will be used to parse
  the XML response from the European Central Bank (ECB).
  """

  @type rate :: %{currency: String.t(), rate: String.t()}
  @type rate_map :: %{rates: list(rate()), time: String.t()}

  @doc """
  Parse the XML response body from the European Central Bank (ECB).
  """
  @callback parse_rates(binary) :: list(rate())

  def parser_mod,
    do: Application.get_env(:forex, :feed_parser, Forex.Feed.SweetXmlParser)

  def parse_rates(body), do: parser_mod().parse_rates(body)
end
