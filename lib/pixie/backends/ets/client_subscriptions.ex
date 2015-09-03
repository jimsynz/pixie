defmodule Pixie.Backend.ETS.ClientSubscriptions do
  use GenServer

  @moduledoc """
  This process keeps track of all client subscriptions.
  """

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:bag, :protected, :named_table, read_concurrency: true]
    Process.flag :trap_exit, true
    {:ok, table}
  end

  def get client_id do
    :ets.select __MODULE__, [{{client_id, :"$2"}, [], [:"$2"]}]
  end

  def subscribed? client_id, channel_name do
    case :ets.select_count __MODULE__, [{{client_id, channel_name}, [], [true]}] do
      0 -> false
      _ -> true
    end
  end

  def subscribe client_id, channel_name do
    GenServer.cast __MODULE__, {:subscribe, client_id, channel_name}
  end

  def unsubscribe client_id, channel_name do
    GenServer.cast __MODULE__, {:unsubscribe, client_id, channel_name}
  end

  def handle_cast {:subscribe, client_id, channel_name}, table do
    :ets.insert __MODULE__, {client_id, channel_name}
    {:noreply, table}
  end

  def handle_cast {:unsubscribe, client_id, channel_name}, table do
    :ets.delete_object __MODULE__, {client_id, channel_name}
    {:noreply, table}
  end
end
