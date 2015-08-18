defmodule Pixie.Engines.Memory.State do
  defstruct server: nil, options: nil, namespace: nil, clients: nil, channels: nil

  alias Pixie.Engines.Memory.State
  alias Pixie.Namespace
  alias Pixie.Server

  def init server, options do
    %State{server: server, options: options} |> reset
  end

  def create_client %State{server: server}=state do
    client_id = Namespace.generate
    Server.debug server, "Creating new client #{client_id}"
    Server.handshake server, client_id
    {client_id, state}
  end

  def destroy_client %State{server: server, clients: clients}=state, client_id do
    if Namespace.exists? client_id do
      if Map.has_key? clients, client_id do
        channels = Map.get clients, client_id
        Enum.each channels, fn(channel)->
          state = unsubscribe state, client_id, channel
        end
      end
      Namespace.release client_id
      Server.debug server, "Destroyed client #{client_id}"
      Server.disconnect server, client_id
      Server.close server, client_id
    end
    state
  end

  def subscribe %State{clients: clients, channels: channels, server: server}=state, client_id, channel do
    client_channels = Map.get clients, client_id, HashSet.new
    should_trigger  = Set.member? client_channels, channel
    client_channels = Set.put client_channels, channel
    clients         = Map.put clients, client_id, client_channels

    channel_clients = Map.get channels, channel, HashSet.new
    channel_clients = Set.put channel_clients, client_id
    channels        = Map.put channels, channel, channel_clients

    state = %{state | clients: clients, channels: channels}

    Server.debug server, "Subscribed client #{client_id} to channel #{channel}"
    if should_trigger do
      Server.subscribe server, client_id, channel
    end
    state
  end

  def unsubscribe %State{clients: clients, channels: channels, server: server}=state, client_id, channel do
    client_channels = Map.get clients, client_id, HashSet.new
    should_trigger  = Set.member? client_channels, channel
    client_channels = Set.delete client_channels, channel
    clients         = Map.put clients, client_id, client_channels
    if Set.size(client_channels) == 0 do
      clients = Map.delete clients, client_id
    end

    channel_clients = Map.get channels, channel, HashSet.new
    channel_clients = Set.delete channel_clients, client_id
    channels        = Map.put channels, channel, channel_clients
    if Set.size(channel_clients) == 0 do
      channels = Map.delete channels, channel
    end

    state = %{state | clients: clients, channels: channels}

    Server.debug server, "Unsubscribed client #{client_id} from channel #{channel}"
    if should_trigger do
      Server.unsubscribe server, client_id, channel
    end

    state
  end

  defp reset %State{}=state do
    %{state |
      namespace: Namespace.generate,
      clients:   %{},
      channels:  %{}
    }
  end
end
