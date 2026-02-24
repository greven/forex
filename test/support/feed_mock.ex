defmodule Forex.FeedMock do
  @moduledoc false

  @behaviour Forex.Feed.API

  import Forex.FeedFixtures

  @impl true
  def get_latest_rates(type: :error) do
    {:error, "Feed API Error"}
  end

  def get_latest_rates(_) do
    {:ok, daily_feed_fixture()}
  end

  @impl true
  def get_last_ninety_days_rates(type: :error) do
    {:error, "Feed API Error"}
  end

  def get_last_ninety_days_rates(_) do
    {:ok, multiple_days_feed_fixture()}
  end

  @impl true
  def get_historic_rates(type: :error) do
    {:error, "Feed API Error"}
  end

  def get_historic_rates(_) do
    {:ok, multiple_days_feed_fixture()}
  end
end
