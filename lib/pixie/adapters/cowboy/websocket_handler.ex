defmodule Pixie.Adapter.Cowboy.WebsocketHandler do
  require Logger
  @behaviour :cowboy_websocket_handler

  def init _transport, req, opts do
    init req, opts
  end

  def init req, opts do
    {:upgrade, :protocol, :cowboy_websocket, req, opts}
  end

  def upgrade req, env, _handler, handler_opts do
    :cowboy_websocket.upgrade req, env, __MODULE__, handler_opts
  end

  def websocket_init _transport, req, state do
    {:ok, req, state}
  end

  def websocket_handle {:text, data}, req, state do
    data = Poison.decode! data
    case Pixie.Protocol.handle data do
      :ok ->
        {:ok, req, state}
      [] ->
        {:ok, req, state}
      responses when is_list(responses) ->
        {:reply, {:text, Poison.encode!(responses)}, req, state}
      unknown ->
        Logger.debug "Unknown response from Protocol: #{inspect unknown}"
        Logger.debug "closing socket."
        {:shutdown, req, state}
    end
  end

  def websocket_handle frame, req, state do
    :cowboy_websocket.handle frame, req, state
  end

  def websocket_info {:deliver, messages}, req, state do
    frame = Poison.encode! messages
    {:reply, {:text, frame}, req, state}
  end

  def websocket_info :close, req, state do
    {:shutdown, req, state}
  end

  def websocket_info msg, req, state do
    {:ok, req, state}
  end

  def websocket_terminate _msg, _req, _state do
    :ok
  end
end
