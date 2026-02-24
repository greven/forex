import Config

config :forex, :feed_api, Forex.FeedMock
config :forex, :cache_module, Forex.CacheMock

config :logger, level: :error
