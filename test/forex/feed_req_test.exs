defmodule Forex.FeedReqTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  @bad_feed_url "https://these-are-not-the-droids-you-are-looking-for.io"

  describe "get_latest_rates/1" do
    test "fetches the latest exchange rates from the European Central Bank (ECB)" do
      assert {:ok, body} = Forex.Feed.Req.get_latest_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency='USD'")

      assert {:error, _} = Forex.Feed.Req.get_latest_rates(url: @bad_feed_url)
    end
  end

  describe "get_last_ninety_days_rates/1" do
    test "fetches the exchange rates from the last ninety days from the ECB" do
      assert {:ok, body} = Forex.Feed.Req.get_last_ninety_days_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency=\"GBP\"")

      assert {:error, _} = Forex.Feed.Req.get_last_ninety_days_rates(url: @bad_feed_url)
    end
  end

  describe "get_historic_rates/1" do
    test "fetches the historic exchange rates feed from the ECB" do
      assert {:ok, body} = Forex.Feed.Req.get_historic_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency=\"JPY\"")

      assert {:error, _} = Forex.Feed.Req.get_historic_rates(url: @bad_feed_url)
    end
  end
end
