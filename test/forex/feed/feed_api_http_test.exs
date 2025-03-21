defmodule Forex.FeedAPIHTTPTest do
  use ExUnit.Case

  alias Forex.Feed.API

  @moduletag :integration

  @bad_feed_url "https://these-are-not-the-droids-you-are-looking-for.io"

  setup do
    Forex.Cache.reset()
    :ok
  end

  describe "get_latest_rates/1" do
    test "fetches the latest exchange rates from the European Central Bank (ECB)" do
      assert {:ok, body} = API.HTTP.get_latest_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency='USD'")

      assert {:error, _} = API.HTTP.get_latest_rates(url: @bad_feed_url)
    end
  end

  describe "get_last_ninety_days_rates/1" do
    test "fetches the exchange rates from the last ninety days from the ECB" do
      assert {:ok, body} = API.HTTP.get_last_ninety_days_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency=\"GBP\"")

      assert {:error, _} = API.HTTP.get_last_ninety_days_rates(url: @bad_feed_url)
    end
  end

  describe "get_historic_rates/1" do
    test "fetches the historic exchange rates feed from the ECB" do
      assert {:ok, body} = API.HTTP.get_historic_rates()
      assert String.starts_with?(body, "<?xml version=")
      assert String.contains?(body, "<Cube currency=\"JPY\"")

      assert {:error, _} = API.HTTP.get_historic_rates(url: @bad_feed_url)
    end
  end
end
