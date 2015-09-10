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
          {:_, Pixie.Adapter.Cowboy.HttpHandler, {Pixie.Server.Plug, []}}
        ]
      }
    ])
  end

  defp default_config do
    [
      port: port,
      max_connections: :infinity
    ]
  end

  defp port do
    case System.get_env("PORT") do
      nil -> 4000
      i   -> String.to_integer(i)
    end
  end
end
