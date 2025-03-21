defmodule Forex.Feed.API do
  @moduledoc """
  This module is responsible for defining the behaviour of the feed (HTTP) client.
  """

  @callback get_latest_rates(options :: keyword()) :: {:ok, binary} | {:error, term()}

  @callback get_last_ninety_days_rates(options :: keyword()) ::
              {:ok, binary} | {:error, term()}

  @callback get_historic_rates(options :: keyword()) :: {:ok, binary} | {:error, term()}
end
