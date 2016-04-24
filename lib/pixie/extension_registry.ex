defmodule Pixie.ExtensionRegistry do
  use GenServer
  alias Pixie.Event

  def start_link modules do
    GenServer.start_link __MODULE__, modules, name: __MODULE__
  end

  def init modules do
    table = :ets.new __MODULE__, [:ordered_set, :protected, :named_table, read_concurrency: true]
    :ets.insert table, Enum.map(modules, fn(mod)-> {now,mod} end)
    {:ok, table}
  end

  def register extension do
    GenServer.call __MODULE__, {:register, extension}
  end

  def unregister extension do
    GenServer.call __MODULE__, {:unregister, extension}
  end

  def registered_extensions do
    Enum.map :ets.tab2list(__MODULE__), fn({_,mod})-> mod end
  end

  def incoming %Event{}=event do
    Enum.reduce_while :ets.tab2list(__MODULE__), event, fn
      ({_, mod}, %{response: %{error: nil}}=e) ->
        {:cont, apply(mod, :incoming, [e])}
      (_, e) ->
        {:halt, e}
    end
  end

  def outgoing %{}=message do
    Enum.reduce :ets.tab2list(__MODULE__), message, fn
      ({_,mod},m)->
        apply(mod, :outgoing, [m])
    end
  end

  def handle_call {:register, extension}, _from, table do
    :ets.insert table, {now, extension}
    {:reply, :ok, table}
  end

  def handle_call {:unregister, extension}, _from, table do
    :ets.match_delete table, {:_, extension}
    {:reply, :ok, table}
  end

  defp now do
    Timex.Time.now |> Timex.Time.to_usecs
  end
end
