defmodule Pixie.Adapter.Cowboy.WebsocketHandler do
  require Logger
  @behaviour :cowboy_websocket_handler
  @max_messages_per_frame 64

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
        send self, {:deliver, responses}
        {:ok, req, state}
      unknown ->
        Logger.debug "Unknown response from Protocol: #{inspect unknown}"
        Logger.debug "closing socket."
        {:shutdown, req, state}
    end
  end

  def websocket_handle frame, req, state do
    :cowboy_websocket.handle frame, req, state
  end

  def websocket_info {:deliver, []}, req, state do
    {:ok, req, state}
  end

  def websocket_info {:deliver, messages}, req, state do
    {to_deliver, rest} = Enum.split(messages, @max_messages_per_frame)

    json = to_deliver
    |> monitor_deliveries
    |> Pixie.JsonEncoderCache.encode!

    deliver_messages rest

    {:reply, {:text, json}, req, state}
  end

  def websocket_info :close, req, state do
    {:shutdown, req, state}
  end

  def websocket_info _msg, req, state do
    {:ok, req, state}
  end

  def websocket_terminate _msg, _req, _state do
    :ok
  end

  defp monitor_deliveries to_deliver do
    Enum.each to_deliver, fn(m)->
      Pixie.Monitor.delivered_message m
    end

    to_deliver
  end

  defp deliver_messages [] do
    nil
  end

  defp deliver_messages to_deliver do
    send self, {:deliver, to_deliver}
  end
end
