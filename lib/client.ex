require Logger

defmodule Pixie.Client do
  use GenServer
  @valid_states ~w| unconnected connecting connected disconnected |a

  defstruct state:      :unconnected,
            id:         nil,
            channels:   HashSet.new,
            message_id: 0,
            transport:  nil,
            subscriptions: HashSet.new

  alias Pixie.Client
  alias Pixie.Client.State

  def start_link id do
    GenServer.start_link __MODULE__, id
  end

  def init id do
    {:ok, %Client{id: id}}
  end

  # Client state related...
  def unconnected?(c),  do: GenServer.call(c, :unconnected?)
  def connecting?(c),   do: GenServer.call(c, :connecting?)
  def connected?(c),    do: GenServer.call(c, :connected?)
  def disconnected?(c), do: GenServer.call(c, :disconnected?)
  def connecting!(c),   do: GenServer.cast(c, :connecting!)
  def connected!(c),    do: GenServer.cast(c, :connected!)
  def disconnected!(c), do: GenServer.cast(c, :disconnected!)

  def client_id(c),     do: GenServer.call(c, :client_id)
  def transport(c, t),  do: GenServer.call(c, {:set_transport, t})
  def transport(c),     do: GenServer.call(c, :get_transport)
  def subscribe(c, channel), do: GenServer.call(c, {:subscribe, channel})
  def unsubscribe(c, channel), do: GenServer.call(c, {:unsubscribe, channel})
  def subscribed?(c, channel_name), do: GenServer.call(c, {:subscribed?, channel_name})
  def publish(c, message), do: GenServer.cast(c, {:publish, message})

  def handle_call(:unconnected?, _f, c),  do: {:reply, State.unconnected?(c), c}
  def handle_call(:connecting?, _f, c),   do: {:reply, State.connecting?(c), c}
  def handle_call(:connected?, _f, c),    do: {:reply, State.connected?(c), c}
  def handle_call(:disconnected?, _f, c), do: {:reply, State.disconnected?(c), c}

  def handle_call(:client_id, _f, %{id: id}=c), do: {:reply, id, c}

  def handle_call({:set_transport, tname1}, _from, %{transport: {tname2, transport}}=state) when tname1 == tname2 do
    {:reply, transport, state}
  end

  def handle_call {:set_transport, transport_name}, _from, %{id: id}=state do
    {:ok, transport} = Pixie.Transport.get transport_name, id
    {:reply, transport, %{state | transport: {transport_name, transport}}}
  end

  def handle_call :get_transport, _from, %{transport: transport}=state do
    {:reply, transport, state}
  end

  def handle_call {:subscribe, channel}, _from, %{subscriptions: subs}=state do
    subs = Set.put subs, channel
    {:reply, :ok, %{state | subscriptions: subs}}
  end

  def handle_call {:unsubscribe, channel}, _from, %{subscriptions: subs}=state do
    subs = Set.delete subs, channel
    {:reply, :ok, %{state | subscriptions: subs}}
  end

  def handle_call {:subscribed?, channel}, _from, %{subscriptions: subs}=state do
    matches = Enum.any?(subs, fn(sub)-> Pixie.Channel.matches? sub, channel end)
    {:reply, matches, state}
  end

  def handle_cast(:connecting!, c),   do: {:noreply, State.connecting!(c)}
  def handle_cast(:connected!, c),    do: {:noreply, State.connected!(c)}
  def handle_cast(:disconnected!, c), do: {:noreply, State.disconnected!(c)}

  # We can't do anything if the client has no connected transport.
  # FIXME We should queue these on the client and despool them once
  # the client is active again.
  def handle_cast({:publish, message}, %{transport: nil}=state) do
    Logger.debug "Discarding message: #{inspect message}, no transport available"
    {:noreply, state}
  end

  def handle_cast({:publish, message}, %{transport: {_, transport}}=state) do
    Pixie.Transport.enqueue transport, [message]
    {:noreply, state}
  end
end
