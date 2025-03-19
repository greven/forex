import Config

config :forex,
  json_library: JSON

import_config "#{Mix.env()}.exs"
