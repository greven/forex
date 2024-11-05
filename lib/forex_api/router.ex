defmodule ForexAPI.Router do
  use ForexAPI, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end
end
