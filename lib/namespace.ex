# Ensure that only unique namespaces are generated.
# This probably needs to be rewritten in terms of a Redis backend if we decide to go that way.

defmodule Pixie.Namespace do
  use GenServer
  alias Pixie.UniqueId, as: Id

  def start_link do
    GenServer.start_link __MODULE__, initial_state, name: __MODULE__
  end

  def generate do
    GenServer.call __MODULE__, :generate
  end

  def release id do
    GenServer.cast __MODULE__, {:release, id}
  end

  def exists? id do
    GenServer.call __MODULE__, {:exists?, id}
  end

  def handle_call :generate, _from, used do
    {id, used} = generate_id used
    {:reply, id, used}
  end

  def handle_cast {:release, id}, used do
    used = Set.delete used, id
    {:noreply, used}
  end

  def handle_call {:exists?, id}, used do
    {:reply, Set.member(used, id), used}
  end

  defp initial_state do
    HashSet.new
  end

  defp generate_id used do
    id = Id.generate
    if Set.member? used, id do
      generate_id used
    else
      used = Set.put used, id
      {id, used}
    end
  end

end
