defmodule Pixie.Channel do
  use GenServer
  defstruct name: nil, clients: HashSet.new

  def start_link name do
    GenServer.start_link __MODULE__, name
  end

  def init name do
    {:ok, %Pixie.Channel{name: name}}
  end

  def subscribe channel, client do
    GenServer.call channel, {:subscribe, client}
  end

  def handle_call {:subscribe, client}, _from, %{clients: clients}=state do
    clients = Set.put clients, client
    {:reply, :ok, %{state | clients: clients}}
  end
end