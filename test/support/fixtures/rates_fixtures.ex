defmodule Forex.RatesFixtures do
  @moduledoc false

  alias Forex.Feed
  alias Forex.Support

  @data_dir Path.join(:code.priv_dir(:forex), "data")

  def single_forex_fixture do
    File.read!(Path.join(@data_dir, "eurofxref-single.xml"))
    |> Feed.Parser.parse_rates()
    |> Enum.map(fn %{time: datetime, rates: rates} ->
      %Forex{
        base: :eur,
        date: Support.map_date(datetime),
        rates: map_rates(rates)
      }
    end)
    |> List.first()
  end

  defp map_rates(rates) do
    rates
    |> Enum.map(fn %{currency: currency, rate: value} ->
      {Support.atomize_code(currency), Support.format_value(value, :decimal)}
    end)
    |> Enum.into(%{})
  end
end
