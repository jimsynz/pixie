defmodule Pixie.Client do
  use GenServer
  require Logger

  defstruct id: nil, transport_name: nil, metadata: nil
  alias __MODULE__

  def start_link id do
    GenServer.start_link __MODULE__, id, name: via(id)
  end

  def init id do
    Process.flag :trap_exit, true
    {:ok, %Client{id: id}, idle_timeout}
  end

  def terminate _reason, %Client{id: id} do
    Logger.debug "[#{id}]: Client terminating"
    Pixie.TransportSupervisor.terminate_child id
    :ok
  end

  @doc """
  Set the active transport to the connected client.
  """
  def set_transport client_id, transport_name do
    GenServer.call via(client_id), {:set_transport, transport_name}
  end

  @doc """
  Retrieve the active transport.
  """
  def transport client_id do
    Pixie.TransportSupervisor.whereis client_id
  end

  @doc """
  Deliver some messages to the client in question.
  """
  def deliver client_id, messages do
    case Pixie.TransportSupervisor.whereis client_id do
      nil ->
        Pixie.Backend.queue_for client_id, messages
      pid ->
        GenServer.cast via(client_id), :ping
        Pixie.Transport.enqueue pid, messages
    end
    :ok
  end

  @doc """
  Explicitly tell the client to check for new messages in the backend
  mailbox.
  """
  def dequeue client_id do
    GenServer.cast via(client_id), :dequeue
  end

  @doc """
  Explicitly ping the client to stop it from timing out.
  """
  def ping client_id do
    GenServer.cast via(client_id), :ping
  end

  @doc """
  Store arbitrary metadata about a client
  """
  def set_meta client_id, metadata do
    GenServer.call via(client_id), {:set_meta, metadata}
  end

  @doc """
  Retrieve metadata about a client
  """
  def get_meta client_id do
    GenServer.call via(client_id), :get_meta
  end

  @doc """
  Get create a process for the transport we're using, also dequeue any messages
  waiting for us in the backend.
  """
  def handle_call {:set_transport, transport_name}, _form, %{id: id, transport_name: nil}=state do
    {:ok, transport} = Pixie.TransportSupervisor.start_child transport_name, id
    do_set_transport id, transport, transport_name
    {:reply, transport, %{state | transport_name: transport_name}, idle_timeout}
  end

  def handle_call({:set_transport, transport_name}, _from, %{id: id, transport_name: old_transport_name}=state)
  when transport_name == old_transport_name do
    transport = Pixie.TransportSupervisor.whereis id
    Pixie.Transport.enqueue transport, Pixie.Backend.dequeue_for(id)
    {:reply, transport, state, idle_timeout}
  end

  def handle_call({:set_transport, transport_name}, _from, %{id: id, transport_name: old_transport_name}=state)
  when transport_name != old_transport_name do
    {:ok, transport} = Pixie.TransportSupervisor.replace_child transport_name, id
    do_set_transport id, transport, transport_name
    {:reply, transport, %{state | transport_name: transport_name}, idle_timeout}
  end

  def handle_call({:set_meta, metadata}, _from, state) do
    {:reply, :ok, %{state | metadata: metadata}}
  end

  def handle_call(:get_meta, _from, %{metadata: metadata}=state) do
    {:reply, metadata, state}
  end

  @doc """
  Dequeue messages to the transport if possible.
  """
  def handle_cast :dequeue, %{id: id}=state do
    case Pixie.TransportSupervisor.whereis id do
      nil -> nil
      pid ->
        messages  = Pixie.Backend.dequeue_for id
        Pixie.Transport.enqueue pid, messages
    end
    {:noreply, state, idle_timeout}
  end

  def handle_cast :ping, %{id: id}=state do
    Pixie.Backend.ping_client id
    {:noreply, state, idle_timeout}
  end

  def handle_info :timeout, %{id: id}=state do
    Task.async fn ->
      Pixie.Backend.destroy_client id, "Idle timeout."
    end
    {:noreply, state}
  end

  def handle_info {:EXIT, _pid, _reason}, state do
    {:noreply, state}
  end

  defp idle_timeout do
    Pixie.timeout * 4
  end

  defp do_set_transport id, transport, transport_name do
    Pixie.Transport.enqueue transport, Pixie.Backend.dequeue_for(id)
    Logger.debug "[#{id}]: Using transport #{transport_name}."
  end

  defp via client_id do
    {:via, :gproc, {:n, :l, {__MODULE__, client_id}}}
  end
end
