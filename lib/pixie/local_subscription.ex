defmodule Pixie.LocalSubscription do
  use GenServer

  def start_link channel_name, callback do
    GenServer.start_link __MODULE__, {channel_name, callback}
  end

  def init {channel_name,callback} do
    {client_id, client_pid} = Pixie.Backend.create_client
    transport_pid           = Pixie.Client.set_transport client_pid, "local"
    Pixie.Backend.subscribe client_id, channel_name
    Pixie.Transport.connect transport_pid, []
    state = %{
      channel_name:  channel_name,
      callback:      callback,
      client_id:     client_id,
      client_pid:    client_pid,
      transport_pid: transport_pid
    }
    {:ok, state, ping_timeout}
  end

  def unsubscribe pid do
    GenServer.cast pid, :unsubscribe
  end

  def handle_info :timeout, %{client_pid: pid}=state do
    Pixie.Client.ping pid
    {:noreply, state, ping_timeout}
  end

  def handle_info {_ref, messages}, %{callback: callback}=state do
    Enum.each messages, fn(message)->
      callback.(message, self)
    end
    {:noreply, state, ping_timeout}
  end

  def handle_cast :unsubscribe, %{client_id: client_id} do
    Pixie.Backend.destroy_client client_id
    {:stop, :normal, nil}
  end

  defp ping_timeout do
    Pixie.timeout
  end
end
