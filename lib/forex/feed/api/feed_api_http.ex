defmodule Forex.Feed.API.HTTP do
  @moduledoc """
  The default HTTP API module for fetching the exchange rates from the European Central Bank (ECB).
  It implements the `Forex.Feed.API` behaviour and it uses `Req` as the HTTP client.

  To use a different HTTP client, just set the `:feed_api` configuration option, for example:

      config :forex, feed_api: MyApp.MyForexHTTPClient
  """

  alias Forex.Feed

  @behaviour Forex.Feed.API

  @impl true
  def get_current_rates(options \\ []) do
    get(:current_rates, options)
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def get_last_ninety_days_rates(options \\ []) do
    get(:last_ninety_days_rates, options)
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def get_historic_rates(options \\ []) do
    options = Keyword.merge([compress_body: true], options)

    get(:historic_rates, options)
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get(feed, options) when is_atom(feed) do
    options = Keyword.merge([url: Feed.path(feed)], options)
    base_url = Feed.base_url()

    Req.new(base_url: base_url)
    |> Req.get(options)
  end
end
