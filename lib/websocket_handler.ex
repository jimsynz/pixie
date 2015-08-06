defmodule Pixie.WebsocketHandler do
  @behaviour :cowboy_websocket_handler

  def init _transport, req, opts do
    init req, opts
  end

  def init req, opts do
    {:upgrade, :protocol, :cowboy_websocket, req, opts}
  end

  def upgrade req, env, handler, handler_opts do
    :cowboy_websocket.upgrade req, env, __MODULE__, handler_opts
  end

  def websocket_init _transport, req, state do
    {:ok, req, state}
  end

  def websocket_handle frame, req, state do
    IO.inspect frame
    {:ok, req, state}
  end

  def websocket_info msg, req, state do
    IO.inspect msg
    {:ok, req, state}
  end

  def websocket_terminate _msg, _req, _state do
    :ok
  end
end
