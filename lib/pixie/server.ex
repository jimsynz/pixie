defmodule Pixie.Server do
  require Logger

  def start_link do
    Logger.info "Running Pixie server with Cowboy on port #{port} (http)"
    :cowboy.start_http(:http, 100, default_config, [env: [dispatch: dispatch]])
  end

  defp dispatch do
    :cowboy_router.compile([
      {
        :_, [
          {:_, Plug.Adapters.Cowboy.Handler, {Pixie.Server.Plug, []}}
        ]
      }
    ])
  end

  defp default_config do
    [port: port]
  end

  defp port do
    System.get_env("PORT") || 4000
  end
end
