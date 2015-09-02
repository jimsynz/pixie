defmodule Pixie.Backend.ETS.Namespaces do
  use GenServer

  @moduledoc """
  This process manages the generation and removal of unique identifiers.
  These are mostly used for client ID's, but can be other stuff too.
  """

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:set, :protected]
    Process.flag :trap_exit, true
    {:ok, table}
  end

  def generate_namespace length do
    GenServer.call __MODULE__, {:generate_namespace, length}
  end

  def release_namespace namespace do
    GenServer.cast __MODULE__, {:release_namespace, namespace}
  end

  def handle_call {:generate_namespace, length}, _from, table do
    id = generate_unique_namespace length, table
    {:reply, id, table}
  end

  def handle_cast {:release_namespace, namespace}, table do
    :ets.delete table, namespace
    {:noreply, table}
  end

  defp generate_unique_namespace length, table do
    id = Pixie.Utils.RandomId.generate length

    case :ets.lookup table, id do
      [{^id}] ->
        generate_unique_namespace length, table
      [] ->
        :ets.insert table, {id}
        id
    end
  end
end
