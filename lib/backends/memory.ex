defmodule Pixie.Backend.Memory do
  use GenServer

  def start_link name, opts do
    GenServer.start_link __MODULE__, opts, name: name
  end

  def init(opts) do
    {:ok, %{
        options:    opts,
        namespaces: HashSet.new,
        clients:    %{}
      }}
  end

  def handle_call {:generate_namespace, length}, _from, %{namespaces: used}=state do
    {id, used} = generate_id used, length
    {:reply, id, %{state | namespaces: used}}
  end

  def handle_call :stop, from, state do
    GenServer.reply(from, :ok)
    {:stop, :normal, state}
  end

  def handle_call :create_client, _from, %{namespaces: used, clients: clients}=state do
    {id, used} = generate_id used, 32
    client     = Pixie.Client.init(id)
    clients    = Map.put clients, id, client
    {:reply, client, %{state | namespaces: used, clients: clients}}
  end

  def handle_call {:get_client, client_id}, _from, %{clients: clients}=state do
    {:reply, Map.get(clients, client_id), state}
  end

  def handle_cast {:destroy_client, %Pixie.Client{}=client}, %{clients: clients}=state do
    {:noreply, %{state | clients: destroy_client(clients, client)}}
  end

  def handle_cast {:destroy_client, client_id}, %{clients: clients}=state do
    case Map.get clients, client_id do
      nil ->    {:noreply, state}
      client -> {:noreply, %{state | clients: destroy_client(clients, client)}}
    end
  end

  def handle_cast {:release_namespace, namespace}, %{namespaces: used}=state do
    used = Set.delete used, namespace
    {:noreply, %{state | namespaces: used}}
  end

  def terminate _reason, _state do
    try do
      self |> Process.info(:registered_name) |> elem(1) |> Process.unregister
    rescue
      _ -> :ok
    end
    :ok
  end

  defp generate_id used, length do
    id = Pixie.UniqueId.generate length
    if Set.member? used, id do
      generate_id used, length
    else
      used = Set.put used, id
      {id, used}
    end
  end

  defp destroy_client clients, client do
    # TODO unsubscribe channels
    Map.delete clients, client.id
  end
end
