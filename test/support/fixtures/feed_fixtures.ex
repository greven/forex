defmodule Forex.FeedFixtures do
  @moduledoc false

  alias Forex.Feed
  alias Forex.Support

  @data_dir Path.join(:code.priv_dir(:forex), "data")

  def daily_feed_fixture do
    File.read!(Path.join(@data_dir, "eurofxref-single.xml"))
  end

  def single_rate_fixture do
    daily_feed_fixture()
    |> Feed.Parser.parse_rates()
  end

  def multiple_days_feed_fixture do
    File.read!(Path.join(@data_dir, "eurofxref-multiple.xml"))
  end

  def multiple_rates_fixture do
    multiple_days_feed_fixture()
    |> Feed.Parser.parse_rates()
  end

  def get_single_rate_fixture(iso_code) do
    iso_code = Support.stringify_code(iso_code)

    single_rate_fixture()
    |> List.first()
    |> Map.get(:rates)
    |> Enum.find(fn
      %{currency: ^iso_code} -> true
      _ -> false
    end)
    |> case do
      nil -> raise "Rate not found for #{iso_code}"
      rate -> {:ok, rate}
    end
  end

  def get_single_rate_fixture_value(iso_code, opts \\ []) do
    format = Keyword.get(opts, :format, :decimal)
    base = Keyword.get(opts, :base, "EUR")

    rate =
      if base == "EUR" do
        {:ok, currency_rate} = get_single_rate_fixture(iso_code)

        currency_rate[:rate]
        |> Support.format_value(format)
        |> Support.round_value(5)
      else
        {:ok, currency_base_rate} = get_single_rate_fixture(base)

        Decimal.new("1.0")
        |> Decimal.div(currency_base_rate[:rate])
        |> Support.format_value(format)
        |> Support.round_value(5)
      end

    {:ok, rate}
  end
end
