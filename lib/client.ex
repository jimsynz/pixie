defmodule Pixie.Client do
  use GenServer
  @valid_states ~w| unconnected connecting connected disconnected |a

  defstruct state:      :unconnected,
            id:         nil,
            channels:   HashSet.new,
            message_id: 0

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

  def handle_call(:unconnected?, _f, c),  do: {:reply, State.unconnected?(c), c}
  def handle_call(:connecting?, _f, c),   do: {:reply, State.connecting?(c), c}
  def handle_call(:connected?, _f, c),    do: {:reply, State.connected?(c), c}
  def handle_call(:disconnected?, _f, c), do: {:reply, State.disconnected?(c), c}

  def handle_call(:client_id, _f, %{id: id}=c), do: {:reply, id, c}

  def handle_cast(:connecting!, c),   do: {:noreply, State.connecting!(c)}
  def handle_cast(:connected!, c),    do: {:noreply, State.connected!(c)}
  def handle_cast(:disconnected!, c), do: {:noreply, State.disconnected!(c)}
end
