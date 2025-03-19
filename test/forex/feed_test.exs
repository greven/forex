defmodule Forex.FeedTest do
  use ExUnit.Case, async: true

  import Forex.Support.FeedFixtures

  alias Forex.Feed

  describe "base_url/0" do
    test "returns the base URL for the European Central Bank (ECB)" do
      assert Feed.base_url() == "https://www.ecb.europa.eu/stats/eurofxref"
    end
  end

  describe "path/1" do
    test "returns the path for the current rates" do
      assert Feed.path(:current_rates) == "/eurofxref-daily.xml"
    end

    test "returns the path for the last ninety days rates" do
      assert Feed.path(:last_ninety_days_rates) == "/eurofxref-hist-90d.xml"
    end

    test "returns the path for the historic rates" do
      assert Feed.path(:historic_rates) == "/eurofxref-hist.xml"
    end
  end

  describe "api_mod/0" do
    test "returns the API adapter module" do
      assert Feed.api_mod() == Forex.Support.FeedAPIMock
    end
  end

  describe "current_rates/1" do
    test "fetches the latest exchange rates from the European Central Bank (ECB)" do
      assert Feed.current_rates() == {:ok, single_rate_fixture()}
      assert Feed.current_rates(type: :error) == {:error, {Forex.FeedError, "Feed API Error"}}
    end
  end

  describe "last_ninety_days_rates/1" do
    test "fetches the exchange rates for the last ninety days from the European Central Bank (ECB)" do
      assert Feed.last_ninety_days_rates() ==
               {:ok, multiple_rates_fixture()}

      assert Feed.last_ninety_days_rates(type: :error) ==
               {:error, {Forex.FeedError, "Feed API Error"}}
    end
  end

  describe "historic_rates/1" do
    test "fetches the historic exchange rates from the European Central Bank (ECB)" do
      assert Feed.historic_rates() ==
               {:ok, multiple_rates_fixture()}

      assert Feed.historic_rates(type: :error) ==
               {:error, {Forex.FeedError, "Feed API Error"}}
    end
  end
end
