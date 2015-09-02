defmodule Pixie.Backend.ETS.ChannelSubscriptions do
  use GenServer

  @moduledoc """
  This process keeps track of all channel subscriptions.
  """

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:bag, :protected, :named_table, read_concurrency: true]
    Process.flag :trap_exit, true
    {:ok, table}
  end

  def get channel_name do
    :ets.select __MODULE__, [{{channel_name, :"$2"}, [], [:"$2"]}]
  end

  def subscriber_count channel_name do
    :ets.select_count __MODULE__, [{{channel_name, :"$2"}, [], [true]}]
  end

  def subscribe channel_name, client_id do
    GenServer.cast __MODULE__, {:subscribe, channel_name, client_id}
  end

  def unsubscribe channel_name, client_id do
    GenServer.cast __MODULE__, {:unsubscribe, channel_name, client_id}
  end

  def handle_cast {:subscribe, channel_name, client_id}, table do
    :ets.insert __MODULE__, {channel_name, client_id}
    {:noreply, table}
  end

  def handle_cast {:unsubscribe, channel_name, client_id}, table do
    :ets.delete_object __MODULE__, {channel_name, client_id}
    {:noreply, table}
  end
end
