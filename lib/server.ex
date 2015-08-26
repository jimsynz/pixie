require Logger

defmodule Pixie.Server do

  def start_link do
    Logger.info "Running Pixie server with Cowboy on port #{port} (http)"
    :cowboy.start_http(:http, 100, default_config, [env: [dispatch: dispatch], onresponse: &log/4])
  end

  defp dispatch do
    :cowboy_router.compile([
      {
        :_, [
          {"/pixie",   Pixie.Adapters.CowboyHttp, []},
          {"/",        :cowboy_static, {:priv_file, :pixie, "index.html"}},
          {"/faye.js", :cowboy_static, {:priv_file, :pixie, "faye.js"}}
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

  defp log status, _, _, req do
    {method, req} = :cowboy_req.method(req)
    {path,   req} = :cowboy_req.path(req)
    params = case :cowboy_req.qs(req) do
      {"", _} ->
        %{}
      {s, _} when is_bitstring(s) and byte_size(s) > 0 ->
        :cowboy_req.parse_qs(req)
    end
    Logger.info "#{method} #{path} #{inspect params}: #{status}"
    req
  end
end
