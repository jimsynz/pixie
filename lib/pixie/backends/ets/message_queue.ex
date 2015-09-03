defmodule Pixie.Backend.ETS.MessageQueue do
  use GenServer

  @moduledoc """
  This process keeps track of any messages waiting to be delivered
  to clients.
  """

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:bag, :protected, :named_table, read_concurrency: true]
    Process.flag :trap_exit, true
    {:ok, table}
  end

  def queue client_id, messages do
    GenServer.cast __MODULE__, {:queue, client_id, messages}
  end

  def dequeue client_id do
    messages = :ets.select __MODULE__, [{{client_id, :"$2"}, [], [:"$2"]}]
    case messages do
      [] ->
        []
      messages ->
        GenServer.cast __MODULE__, {:delete, client_id, messages}
        messages
    end
  end

  def handle_cast {:queue, client_id, messages}, table do
    tuples = Enum.map messages, fn(message)-> {client_id, message} end
    :ets.insert __MODULE__, tuples
    {:noreply, table}
  end

  def handle_cast {:delete, client_id, messages}, table do
    Enum.each messages, fn(message)->
      :ets.delete_object __MODULE__, {client_id, message}
    end
    {:noreply, table}
  end
end
