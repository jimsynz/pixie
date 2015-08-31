defmodule Pixie.Adapter.Cowboy.HttpHandler do
  @behaviour :cowboy_handler
  alias Plug.Adapters.Cowboy.Handler, as: PlugHandler

  def init({transport, :http}, req, {plug, opts}) when transport in [:tcp, :ssl] do
    case :cowboy_req.header("upgrade", req) do
      {"websocket", _} ->
        {:upgrade, :protocol, Pixie.Adapter.Cowboy.WebsocketHandler}
      {"WebSocket", _} ->
        {:upgrade, :protocol, Pixie.Adapter.Cowboy.WebsocketHandler}
      _           ->
        {:upgrade, :protocol, __MODULE__, req, {transport, plug, opts}}
    end
  end

  def upgrade req, env, __MODULE__, {transport, plug, opts} do
    PlugHandler.upgrade req, env, PlugHandler, {transport, plug, opts}
  end

end
