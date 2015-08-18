defmodule Pixie.Engines.Memory do
  defstruct pid: nil
  alias Pixie.Server
  alias Pixie.Timeout
  alias Pixie.Engines.Memory
  alias Pixie.Engines.Memory.State
  alias Pixie.Engine
  use GenServer

  def init server, options do
    {:ok, pid} = start_link server, options
    %Memory{pid: pid}
  end

  def start_link server, options do
    GenServer.start_link __MODULE__, State.init(server, options)
  end

  def handle_call :create_client, _from, state do
    {client_id, state} = State.create_client state
    Engine.ping self, client_id
    {:reply, client_id, state}
  end

  def handle_call {:destroy_client, client_id}, _from, state do
    state = State.destroy_client(state, client_id)
    Timeout.remove client_id
    {:reply, :ok, state}
  end

  def handle_call {:subscribe, client_id, channel}, _from, state do
    {:reply, :ok, State.subscribe(state, client_id, channel)}
  end

  def handle_call {:unsubscribe, client_id, channel}, _from, state do
    {:reply, :ok, State.unsubscribe(state, client_id, channel)}
  end

  def handle_cast {:ping, engine, client_id}, %State{server: server}=state do
    timeout = Server.timeout server
    Server.debug server, "Ping #{client_id}, timeout #{timeout}"
    Timeout.remove client_id
    Timeout.add client_id, 2*timeout, Engine, :destroy_client, [engine, client_id]
    {:noreply, state}
  end

  def handle_cast {:publish, message, channels}, %State{server: server, channels: channels}=state do
    Server.debug server, "Publishing message #{inspect message}"

    deliver_to_clients = Enum.reduce channels, HashSet.new, fn(channel, acc)->
      channel_clients = Map.get channels, channel, HashSet.new
      Set.union acc, channel_clients
    end

    Enum.each deliver_to_clients, fn(client_id)->
      Server.deliver server, client_id, message
    end

    {:noreply, state}
  end
end
