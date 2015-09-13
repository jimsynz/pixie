defmodule Pixie.Backend.ETS.Channels do
  use GenServer
  import Pixie.Utils.Backend

  @moduledoc false

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:set, :protected, :named_table, read_concurrency: true]
    {:ok, table}
  end

  def create channel_name do
    case get channel_name do
      nil ->
        GenServer.cast __MODULE__, {:create, channel_name}
      _ -> :ok
    end
  end

  def destroy channel_name do
    GenServer.cast __MODULE__, {:destroy, channel_name}
  end

  def exists? channel_name do
    case :ets.lookup __MODULE__, channel_name do
      [{^channel_name, _}] -> true
      []                   -> false
    end
  end

  def get channel_name do
    case :ets.lookup __MODULE__, channel_name do
      [{^channel_name, channel_matcher}] -> channel_matcher
      [] -> nil
    end
  end

  def list do
    :ets.tab2list __MODULE__
  end

  def handle_cast {:create, channel_name}, table do
    channel_matcher = compile_channel_matcher(channel_name)
    :ets.insert __MODULE__, {channel_name, channel_matcher}
    {:noreply, table}
  end

  def handle_cast {:destroy, channel_name}, table do
    :ets.delete table, channel_name
    {:noreply, table}
  end
end
