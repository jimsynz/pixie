defmodule Pixie.ExtensionRegistry do
  use GenServer
  alias Pixie.Event

  def start_link modules do
    GenServer.start_link __MODULE__, modules, name: __MODULE__
  end

  def init modules do
    table = :ets.new __MODULE__, [:bag, :protected, :named_table, read_concurrency: true]
    :ets.insert table, Enum.map(modules, fn(mod)-> {mod,mod} end)
    {:ok, table}
  end

  def register extension do
    GenServer.call __MODULE__, {:register, extension}
  end

  def unregister extension do
    GenServer.call __MODULE__, {:unregister, extension}
  end

  def registered_extensions do
    Enum.map :ets.tab2list(__MODULE__), fn({mod,_})-> mod end
  end

  def incoming %Event{}=event do
    Enum.reduce :ets.tab2list(__MODULE__), event, fn
      ({mod,_},e)->
        apply(mod, :incoming, [e])
    end
  end

  def outgoing %{}=message do
    Enum.reduce :ets.tab2list(__MODULE__), message, fn
      ({mod,_},m)->
        apply(mod, :outgoing, [m])
    end
  end

  def handle_call {:register, extension}, _from, table do
    :ets.insert table, {extension, extension}
    {:reply, :ok, table}
  end

  def handle_call {:unregister, extension}, _from, table do
    :ets.delete table, extension
    {:reply, :ok, table}
  end
end
