defmodule Pixie.LocalSubscription do
  use GenServer

  @moduledoc """
  Represents an in-VM subscription to a Bayeux channel.
  """

  @doc """
  Subscribe to a channel and call the provided function with messages.

  ```elixir
  {:ok, sub} = Pixie.subscribe "/my_awesome_channel", fn(message,_)->
    IO.inspect message
  end
  ```

  The function must take two arguments:
    - A message struct.
    - The subscription pid.
  """
  def subscribe(channel_name, callback) when is_binary(channel_name) and is_function(callback, 2) do
    Pixie.LocalSubscriptionSupervisor.add_worker Pixie.LocalSubscription, {channel_name, callback}, [channel_name, callback]
  end

  @doc """
  Cancel a local subscription.

  Example:

  ```elixir
  Pixie.subscribe "/only_one_please", fn(message,sub)->
    IO.inspect message
    Pixie.unsubscribe sub
  end
  ```
  """
  def unsubscribe pid do
    GenServer.cast pid, :unsubscribe
  end

  def start_link channel_name, callback do
    GenServer.start_link __MODULE__, {channel_name, callback}
  end

  def init {channel_name,callback} do
    {client_id, client_pid} = Pixie.Backend.create_client
    transport_pid           = Pixie.Client.set_transport client_id, "local"
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

  def handle_info :timeout, %{client_pid: pid}=state do
    Pixie.Client.ping pid
    {:noreply, state, ping_timeout}
  end

  def handle_info {_ref, messages}, %{client_pid: pid, callback: callback}=state do
    Pixie.Client.ping pid
    Enum.each messages, fn(message)->
      callback.(message, self)
    end
    {:noreply, state, ping_timeout}
  end

  def handle_cast :unsubscribe, %{client_id: client_id} do
    Pixie.Backend.destroy_client client_id, "Local unsubscription."
    {:stop, :normal, nil}
  end

  defp ping_timeout do
    trunc Pixie.timeout * 0.75
  end
end
