require Logger

defmodule Pixie.Adapter.CowboyWebsocket do
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

  def websocket_handle {:text, data}, req, _state do
    Logger.debug "websocket_handle :text, #{inspect(data)}"
    json = case Pixie.Protocol.handle Poison.decode!(data) do
      [] ->
        nil
      events when is_list(events) ->
        events
          |> Enum.map(fn
            %{response: r}-> r
          end)
          |> Poison.encode!
      %{response: r} when not is_nil(r)->
        Poison.encode! [r]
      _ ->
        nil
    end

    if json do
      Logger.debug "sending frame #{inspect json}"
      {:reply, {:text, json}, req, nil}
    else
      {:ok, req, nil}
    end
  end

  def websocket_handle frame, req, state do
    :cowboy_websocket.handle frame, req, state
  end

  def websocket_info msg, req, state do
    IO.inspect msg
    {:ok, req, state}
  end

  def websocket_terminate _msg, _req, _state do
    :ok
  end
end
