defmodule Forex.Feed.API.HTTP do
  @moduledoc """
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
