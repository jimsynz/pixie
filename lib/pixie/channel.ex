require ExMinimatch

defmodule Pixie.Channel do
  use GenServer
  defstruct name: nil, clients: HashSet.new, match: nil

  def start_link name do
    GenServer.start_link __MODULE__, name
  end

  def init name do
    {:ok, %Pixie.Channel{name: name, match: ExMinimatch.compile(name)}}
  end

  def subscribe channel, client do
    GenServer.call channel, {:subscribe, client}
  end

  def unsubscribe channel, client do
    GenServer.call channel, {:unsubscribe, client}
  end

  def matches? channel, channel_name do
    GenServer.call channel, {:matches?, channel_name}
  end

  def subscribers channel do
    GenServer.call channel, :subscribers
  end

  def handle_call {:subscribe, client}, _from, %{clients: clients}=state do
    clients = Set.put clients, client
    {:reply, :ok, %{state | clients: clients}}
  end

  def handle_call {:unsubscribe, client}, _from, %{clients: clients}=state do
    clients = Set.delete clients, client
    {:reply, Set.size(clients), %{state | clients: clients}}
  end

  def handle_call {:matches?, channel_name}, _from, %{match: compiled_match}=state do
    {:reply, ExMinimatch.match(compiled_match, channel_name), state}
  end

  def handle_call :subscribers, _from, %{clients: clients}=state do
    {:reply, clients, state}
  end
end
