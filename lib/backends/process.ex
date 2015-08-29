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
        clients:    %{}
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

  def handle_cast {:release_namespace, namespace}, state do
    {:noreply, release_namespace(namespace, state)}
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
end
