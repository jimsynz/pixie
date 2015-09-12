use Mix.Config

config :pixie, :subscribe_immediately, true
# config :pixie, :extensions, [Pixie.DebugExtension]
config :pixie, :monitors, [Pixie.LoggingMonitor]
config :pixie, :backend,
  name: :Redis
