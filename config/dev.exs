use Mix.Config

config :pixie, :subscribe_immediately, true
config :pixie, :extensions, [Pixie.DebugExtension]
# config :pixie, :backend,
#   name: :Redis
