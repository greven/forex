defmodule ForexAPI.Endpoint do
  use Phoenix.Endpoint, otp_app: :forex

  plug ForexAPI.Router
end
