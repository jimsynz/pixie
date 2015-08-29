require Logger

defmodule Pixie.Backend.Process do
  use GenServer
  alias Pixie.Supervisor

  def start_link name, opts do
    GenServer.start_link __MODULE__, opts, name: name
  end

  def init(opts) do
    {:ok, %{
        options:    opts,
        namespaces: HashSet.new,
        clients:    %{},
        channels:   %{}
      }}
  end

  def handle_call {:generate_namespace, length}, _from, state do
    {id, state} = generate_namespace length, state
    {:reply, id, state}
  end

  def handle_call :create_client, _from, state do
    {client, state} = create_client state
    {:reply, client, state}
  end

  def handle_call {:get_client, id}, _from, state do
    {:reply, get_client(id, state), state}
  end

  def handle_call {:destroy_client, id}, _from, state do
    state = destroy_client(id, state)
    {:reply, :ok, state}
  end

  def handle_call {:subscribe, client_id, channel}, _from, state do
    {:reply, :ok, subscribe(client_id, channel, state)}
  end

  def handle_call {:unsubscribe, client_id, channel}, _from, state do
    {:reply, :ok, unsubscribe(client_id, channel, state)}
  end

  def handle_cast {:release_namespace, namespace}, state do
    {:noreply, release_namespace(namespace, state)}
  end

  def handle_cast {:publish, message}, %{channels: channels}=state do
    Task.async fn -> publish message, Map.values(channels) end
    {:noreply, state}
  end

  defp generate_id used, length do
    id = Pixie.Utils.RandomId.generate length
    if Set.member? used, id do
      generate_id used, length
    else
      used = Set.put used, id
      {id, used}
    end
  end

  defp generate_namespace length, %{namespaces: used}=state do
    {id, used} = generate_id used, length
    {id, %{state | namespaces: used}}
  end

  defp release_namespace id, %{namespaces: used}=state do
    used = Set.delete used, id
    %{state | namespaces: used}
  end

  defp create_client %{clients: clients}=state do
    {id, state} = generate_namespace 32, state
    {:ok, pid} = Supervisor.add_worker Pixie.Client, id, [id]
    clients = Map.put clients, id, pid
    {{id, pid}, %{state | clients: clients}}
  end

  defp client_exists? id, %{clients: clients} do
    Map.has_key? clients, id
  end

  defp get_client id, %{clients: clients} do
    Map.get clients, id
  end

  defp destroy_client id, %{clients: clients}=state do
    if client_exists? id, state do
      Supervisor.terminate_worker id
      clients = Map.delete clients, id
      state = release_namespace id, state
      %{state | clients: clients}
    else
      state
    end
  end

  defp create_channel channel, %{channels: channels}=state do
    id = "channel:#{channel}"
    {:ok, pid} = Supervisor.add_worker Pixie.Channel, id, [channel]
    channels = Map.put channels, channel, pid
    {pid, %{state | channels: channels}}
  end

  defp destroy_channel channel, %{channels: channels}=state do
    if Map.has_key? channels, channel do
      id = "channel:#{channel}"
      Supervisor.terminate_worker id
      channels = Map.delete channels, channel
      %{state | channels: channels}
    else
      state
    end
  end

  defp get_channel channel, %{channels: channels} do
    Map.get channels, channel
  end

  defp ensure_channel channel, state do
    case get_channel channel, state do
      nil -> create_channel channel, state
      pid -> {pid, state}
    end
  end

  defp subscribe client_id, channel_name, state do
    client           = get_client client_id, state
    {channel, state} = ensure_channel channel_name, state

    Pixie.Client.subscribe client, channel
    Pixie.Channel.subscribe channel, client
    state
  end

  defp unsubscribe client_id, channel_name, state do
    client           = get_client client_id, state
    {channel, state} = ensure_channel channel_name, state

    Pixie.Client.unsubscribe client, channel
    case Pixie.Channel.unsubscribe channel, client do
      0 -> destroy_channel channel, state
      _ -> state
    end
  end

  defp publish %{channel: channel_name}=message, possible_channels do
    Logger.debug "Publishing #{inspect message}"
    # Reduce all subscribed clients to a single set so that
    # each client only receives the message once.
    receivers = Enum.reduce possible_channels, HashSet.new, fn(channel, acc)->
      if Pixie.Channel.matches? channel, channel_name do
        Set.union acc, Pixie.Channel.subscribers(channel)
      else
        acc
      end
    end
    # Publish the message to each client.
    Enum.each receivers, fn(client)->
      Pixie.Client.publish client, message
    end
  end
end
